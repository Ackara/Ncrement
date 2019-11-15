using Acklann.Semver;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Management.Automation;
using System.Reflection;
using System.Text;

namespace Acklann.Ncrement.Extensions
{
    internal static class PSObjectExtensions
    {
        public static void GetManifestInfo(this PSObject pso, out Manifest manifest, out string manifestPath)
        {
            switch (pso.BaseObject)
            {
                case PathInfo pathInfo:
                    manifestPath = pathInfo.Path;
                    break;

                case FileInfo file:
                    manifestPath = file.FullName;
                    break;

                case string absolutePath:
                    manifestPath = absolutePath;
                    break;

                default:
                    manifestPath = null;
                    break;
            }

            if (string.IsNullOrEmpty(manifestPath))
                manifest = ToManifest(pso);
            else if (File.Exists(manifestPath))
                manifest = Manifest.LoadFrom(manifestPath);
            else
                throw new FileNotFoundException($"Could not find file at '{manifestPath}'.");
        }

        public static Manifest ToManifest(this PSObject pso)
        {
            if (pso == null) return null;

            PSMemberInfo source;
            var manifest = new Manifest();
            PSMemberInfoCollection<PSMemberInfo> members = pso.Members;

            var properties = from x in typeof(Manifest).GetMembers()
                             where x.MemberType == MemberTypes.Property
                             select (x as PropertyInfo);

            foreach (PropertyInfo p in properties)
            {
                source = (members[p.Name] ?? members[ToCamelCase(p.Name)]);
                if (source == null) continue;

                switch (p.Name)
                {
                    default: p.SetValue(manifest, source.Value); break;

                    case nameof(Manifest.Version):
                        manifest.Version = ToSemanticVersion(PSObject.AsPSObject(source.Value));
                        break;

                    case nameof(Manifest.BranchVersionMap):
                        manifest.BranchVersionMap = (source.Value is Dictionary<string, string> dic ? dic : null);
                        break;
                }
            }

            return manifest;
        }

        public static SemanticVersion ToSemanticVersion(this PSObject pso)
        {
            if (pso == null) throw new ArgumentNullException(nameof(pso));

            ushort get(string name)
            {
                ushort result = pso.GetValue<ushort>(name.ToLowerInvariant());
                if (result == default) result = pso.GetValue<ushort>(name);
                return result;
            }

            return new SemanticVersion(
                get(nameof(SemanticVersion.Major)),
                get(nameof(SemanticVersion.Minor)),
                get(nameof(SemanticVersion.Patch))
                );
        }

        public static Dictionary<string, string> ToDictionary(this PSObject pso)
        {
            var dic = new Dictionary<string, string>();
            foreach (PSMemberInfo item in pso.Members)
            {
                dic.Add(item.Name, Convert.ToString(item.Value));
            }
            return dic;
        }

        public static T GetValue<T>(this PSObject pso, string memberName)
        {
            PSMemberInfo member;
            foreach (string name in (new string[] { memberName, ToCamelCase(memberName), memberName.ToLowerInvariant() }))
            {
                member = pso.Members[name];
                if (member == null) continue;

                return (T)Convert.ChangeType(member.Value, typeof(T));
            }

            return default(T);
        }

        public static PSObject ToPSObject(this Manifest manifest)
        {
            var result = new PSObject();

            var properties = from p in typeof(Manifest).GetProperties()
                             where p.CanWrite
                             select p;

            string name; object value = null;
            foreach (PropertyInfo p in properties)
            {
                name = p.Name.ToCamelCase();
                value = p.GetValue(manifest);
                if (value == null) continue;

                switch (p.Name)
                {
                    default: result.Properties.Add(new PSNoteProperty(name, value)); break;

                    case nameof(Manifest.Version):
                        var v = (SemanticVersion)value;
                        result.Properties.Add(new PSNoteProperty(name, new
                        {
                            major = v.Major,
                            minor = v.Minor,
                            patch = v.Patch
                        }));
                        break;

                    case nameof(Manifest.VersionFormat):
                        continue;
                }
            }

            return result;
        }

        private static string ToCamelCase(this string text)
        {
            if (string.IsNullOrEmpty(text)) return text;
            else if (text.Length == 1) return text;
            else
            {
                bool allCaps = true;
                var camel = new StringBuilder();
                ReadOnlySpan<char> span = text.AsSpan();

                for (int i = 0; i < span.Length; i++)
                {
                    if (allCaps && !char.IsUpper(span[i])) allCaps = false;

                    if (span[i] == ' ' || span[i] == '_')
                        continue;
                    else if (i == 0)
                        camel.Append(char.ToLowerInvariant(span[i]));
                    else if (span[i - 1] == ' ' || span[i - 1] == '_')
                        camel.Append(char.ToUpperInvariant(span[i]));
                    else
                        camel.Append(span[i]);
                }

                return (allCaps ? text.ToLower() : camel.ToString());
            }
        }
    }
}