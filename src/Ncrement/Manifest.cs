using Acklann.Semver;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Runtime.Serialization;

namespace Acklann.Ncrement
{
    public class Manifest : IManifest
    {
        [DataMember(IsRequired = true)]
        public string Id { get; set; }

        [DataMember(IsRequired = true)]
        public string Name { get; set; }

        public string Description { get; set; }

        [DataMember(IsRequired = true)]
        public SemanticVersion Version { get; set; }

        [IgnoreDataMember]
        public string VersionFormat { get; set; }

        public string Company { get; set; }

        [DataMember(IsRequired = true)]
        public string Authors { get; set; }

        public string Copyright { get; set; }

        public string License { get; set; }

        public string Website { get; set; }

        public string Repository { get; set; }

        public string Icon { get; set; }

        public string ReleaseNotes { get; set; }

        public string Tags { get; set; }

        [DataMember(IsRequired = true)]
        public Dictionary<string, string> BranchVersionMap { get; set; }

        public static Manifest CreateTemplate()
        {
            return new Manifest()
            {
                Copyright = "Copyright {year} {company}, All Rights Reserved.",

                Website = "https://github.com/{company}/{name}",
                Repository = "https://github.com/{company}/{name}.git",
                License = "https://github.com/{company}/{name}/blob/master/license.txt",
                ReleaseNotes = "https://github.com/{company}/{name}/blob/master/release-notes.md",
                Icon = "https://raw.githubusercontent.com/{company}/{name}/master/art/icon.png",

                BranchVersionMap = new Dictionary<string, string>()
                {
                    { "master", "C" },
                    { DEFAULT, "g" }
                }
            };
        }

        public static Manifest LoadFrom(string filePath)
        {
            if (!File.Exists(filePath)) throw new FileNotFoundException($"Could not find file at '{filePath}'.");

            using (var file = new FileStream(filePath, FileMode.Open, FileAccess.Read, FileShare.Read))
            using (var reader = new StreamReader(file))
            {
                return ParseJson(reader.ReadToEnd());
            }
        }

        public static Manifest ParseJson(string text)
        {
            if (string.IsNullOrEmpty(text)) throw new ArgumentNullException(nameof(text));

            var manifest = new Manifest();
            var properties = (from x in typeof(Manifest).GetMembers()
                              where x.MemberType == MemberTypes.Property
                              select (x as PropertyInfo)).ToDictionary(x => x.Name);

            using (var reader = new JsonTextReader(new StringReader(text)))
            {
                string name = null;
                while (reader.Read())
                    if (reader.TokenType == JsonToken.PropertyName)
                    {
                        name = ToPascal(Convert.ToString(reader.Value) ?? string.Empty);

                        if (properties.ContainsKey(name))
                            switch (name)
                            {
                                default: properties[name].SetValue(manifest, reader.ReadAsString()); break;

                                case nameof(Version):
                                    int x = 0, y = 0, z = 0;
                                    string p = null, b = null;

                                    reader.Read();
                                    while (reader.Read() && reader.TokenType == JsonToken.PropertyName)
                                        switch (ToPascal(Convert.ToString(reader.Value)))
                                        {
                                            case nameof(SemanticVersion.Major): x = reader.ReadAsInt32() ?? 0; break;
                                            case nameof(SemanticVersion.Minor): y = reader.ReadAsInt32() ?? 0; break;
                                            case nameof(SemanticVersion.Patch): z = reader.ReadAsInt32() ?? 0; break;

                                            case nameof(SemanticVersion.PreRelease): p = reader.ReadAsString(); break;
                                            case nameof(SemanticVersion.Build): b = reader.ReadAsString(); break;
                                        }

                                    manifest.Version = new SemanticVersion(x, y, z, p, b);
                                    break;

                                case nameof(BranchVersionMap):
                                    if (manifest.BranchVersionMap == null) manifest.BranchVersionMap = new Dictionary<string, string>();

                                    reader.Read();
                                    while (reader.Read() && reader.TokenType == JsonToken.PropertyName)
                                    {
                                        manifest.BranchVersionMap.Add(Convert.ToString(reader.Value), reader.ReadAsString());
                                    }
                                    break;
                            }
                    }
            }

            return manifest;
        }

        public void SetVersionFormat(string branchName)
        {
            if (string.IsNullOrEmpty(branchName)) throw new ArgumentNullException(nameof(branchName));
            if (!string.IsNullOrEmpty(VersionFormat)) return;
            if (BranchVersionMap == null || BranchVersionMap.Count < 1) return;

            if (BranchVersionMap.ContainsKey(branchName))
                VersionFormat = BranchVersionMap[branchName];
            else if (BranchVersionMap.ContainsKey(DEFAULT))
                VersionFormat = BranchVersionMap[DEFAULT];
        }

        public void Save(string filePath)
        {
            if (string.IsNullOrEmpty(filePath)) throw new ArgumentNullException(nameof(filePath));

            switch (Path.GetExtension(filePath).ToLowerInvariant())
            {
                default:
                case ".json": SaveAsJson(filePath); break;

                case ".xml": throw new System.NotImplementedException();
            }
        }

        public void SaveAsJson(string filePath)
        {
            if (string.IsNullOrEmpty(filePath)) throw new ArgumentNullException(nameof(filePath));

            string folder = Path.GetDirectoryName(filePath);
            if (!Directory.Exists(folder)) Directory.CreateDirectory(folder);

            File.WriteAllText(filePath, JsonConvert.SerializeObject(this, new JsonSerializerSettings()
            {
                Formatting = Formatting.Indented,
                NullValueHandling = NullValueHandling.Ignore
            }));
        }

        #region Backing Mebers

        private const string DEFAULT = "default";

        private static string ToPascal(string text)
        {
            if (string.IsNullOrEmpty(text)) return text;
            else if (text.Length == 1) return text.ToUpperInvariant();
            else
            {
                var pascal = new System.Text.StringBuilder();
                ReadOnlySpan<char> span = text.AsSpan();

                for (int i = 0; i < span.Length; i++)
                {
                    if (span[i] == ' ' || span[i] == '_')
                        continue;
                    else if (i == 0)
                        pascal.Append(char.ToUpperInvariant(span[i]));
                    else if (span[i - 1] == ' ' || span[i - 1] == '_')
                        pascal.Append(char.ToUpperInvariant(span[i]));
                    else
                        pascal.Append(span[i]);
                }

                return pascal.ToString();
            }
        }

        #endregion Backing Mebers
    }
}