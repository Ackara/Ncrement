using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.IO;
using System.Xml;
using System.Xml.Linq;
using System.Xml.XPath;

namespace Acklann.Ncrement
{
    public partial class Editor
    {
        public static string UpdateProjectFile(string filePath, Manifest manifest, IDictionary<string, string> tokens = null)
        {
            if (string.IsNullOrEmpty(filePath)) throw new ArgumentNullException(nameof(filePath));

            if (tokens == null) tokens = ReplacementToken.Create();
            ReplacementToken.Append(tokens, manifest);

            string fileName = Path.GetFileName(filePath);
            if (filePath.EndsWith("proj", StringComparison.OrdinalIgnoreCase))
                return UpdateDotnetProjectFile(filePath, manifest, tokens);
            else if (string.Equals(Path.GetFileName(filePath), "package.json", StringComparison.OrdinalIgnoreCase))
                return UpdatePackageJson(filePath, manifest, tokens);
            else switch (Path.GetExtension(filePath).ToLowerInvariant())
                {
                    case ".vsixmanifest": return UpdateVsixManifest(filePath, manifest, tokens);
                }

            throw new NotSupportedException($"'{Path.GetExtension(filePath)}' files are not supported as yet.");
        }

        public static string UpdatePackageJson(string filePath, Manifest manifest, IDictionary<string, string> tokens)
        {
            if (!File.Exists(filePath)) throw new FileNotFoundException($"Could not find file at '{filePath}'.");
            if (manifest == null) throw new ArgumentNullException(nameof(manifest));

            // documentation: https://docs.npmjs.com/files/package.json
            string expand(string input) => ReplacementToken.Expand(input, tokens);
            IEnumerable<(string, object)> map = new (string, object)[]
            {
                ("$.name", expand(manifest?.Name ?? string.Empty).ToLowerInvariant()),
                ("$.description", expand(manifest.Description)),
                ("$.version", expand(manifest.Version.ToString(manifest.VersionFormat?? "G"))),

                ("$.author", expand(manifest.Authors)),
                ("$.license", expand(manifest.License)),

                ("$.homepage", expand(manifest.Website)),
                ("$.repository.url", expand(manifest.Repository)),

                ("$.keywords", expand(manifest.Tags)?.Split(' ', ','))
            };

            JToken token = null;
            var document = JObject.Parse(File.ReadAllText(filePath));
            string getName(string x) => x.Substring(x.LastIndexOf('.') + 1);

            foreach ((string jpath, object value) in map)
                if (value != null)
                {
                    token = document.SelectToken(jpath);
                    if (token == null)
                    {
                        switch (jpath)
                        {
                            default: document.Add(new JProperty(getName(jpath), value)); break;

                            case "$.repository.url":
                                document.Add(new JProperty("repository", new JObject(
                                    new JProperty("type", "git"),
                                    new JProperty("url", value))));
                                break;
                        }
                    }
                    else
                    {
                        (token as JValue).Value = value;
                    }
                }

            return document.ToString();
        }

        internal static string UpdateDotnetProjectFile(string filePath, Manifest manifest, IDictionary<string, string> tokens)
        {
            if (!File.Exists(filePath)) throw new FileNotFoundException($"Could not find file at '{filePath}'.");
            if (manifest == null) throw new ArgumentNullException(nameof(manifest));

            // documentation: https://docs.microsoft.com/en-us/dotnet/core/tools/csproj#nuget-metadata-properties
            string expand(string input) => ReplacementToken.Expand(input, tokens);
            IEnumerable<(string, string)> map = new (string, string)[]
            {
                ("PackageId", expand(manifest.Id)),
                ("Title", expand(manifest.Name)),
                ("Description", expand(manifest.Description)),
                
                ("Version", expand(manifest.Version.ToString(manifest.VersionFormat?? "g"))),
                //("PackageVersion", expand(manifest.Version.ToString(manifest.VersionFormat?? "g"))),
                //("AssemblyVersion", expand(manifest.Version.ToString(manifest.VersionFormat?? "g"))),

                ("PackageIconUrl", expand(manifest.Icon)),
                ("RepositoryUrl", expand(manifest.Repository)),
                ("PackageProjectUrl", expand(manifest.Website)),
                ("PackageReleaseNotes", expand(manifest.ReleaseNotes)),
                ("PackageTags", expand(manifest.Tags)),

                ("Authors", expand(manifest.Authors)),
                ("Copyright", expand(manifest.Copyright)),

                ("PackageLicenseFile", expand(manifest.License))
            };

            var document = XDocument.Load(filePath, LoadOptions.PreserveWhitespace);
            XElement root = document.Root, group = null;

            var namespaces = new XmlNamespaceManager(new NameTable());
            string xmlns = (root.HasAttributes ? root.Attribute("xmlns")?.Value : null) ?? string.Empty;
            string prefix = (string.IsNullOrEmpty(xmlns) ? string.Empty : "ms:");
            if (!string.IsNullOrEmpty(xmlns)) namespaces.AddNamespace(prefix.TrimEnd(':'), xmlns);

            foreach ((string name, string value) in map)
                if (!string.IsNullOrWhiteSpace(value))
                {
                    XElement element = root.XPathSelectElement(string.Format("{0}PropertyGroup/{0}{1}", prefix, name), namespaces);
                    if (element == null)
                    {
                        if (group == null)
                        {
                            group = root.XPathSelectElement($"{prefix}PropertyGroup", namespaces) ?? new XElement(XName.Get("PropertyGroup", xmlns));
                            group.Add(Environment.NewLine);
                            root.Add(Environment.NewLine);
                            root.Add(group);
                            root.Add(Environment.NewLine);
                        }

                        group.Add(new XElement(XName.Get(name, xmlns), value));
                        group.Add(Environment.NewLine);
                    }
                    else
                    {
                        element.SetValue(value);
                    }
                }

            return document.ToString(SaveOptions.DisableFormatting);
        }

        internal static string UpdateVsixManifest(string filePath, Manifest manifest, IDictionary<string, string> tokens)
        {
            // documentation: https://docs.microsoft.com/en-us/visualstudio/extensibility/vsix-extension-schema-2-0-reference?view=vs-2019

            if (!File.Exists(filePath)) throw new FileNotFoundException($"Could not find file at '{filePath}'.");
            if (manifest == null) throw new ArgumentNullException(nameof(manifest));

            string expand(string input) => ReplacementToken.Expand(input, tokens);
            IEnumerable<(string, string)> metaMap = new (string, string)[]
            {
                ("x:Metadata/x:DisplayName", expand(manifest.Name)),
                ("x:Metadata/x:Description", expand(manifest.Description)),
                ("x:Metadata/x:MoreInfo", expand(manifest.Website)),
                ("x:Metadata/x:ReleaseNotes", expand(manifest.ReleaseNotes)),
                ("x:Metadata/x:Tags", expand(manifest.Tags)),
            };

            var document = XDocument.Load(filePath, LoadOptions.PreserveWhitespace);
            XElement root = document.Root, metadata = null;

            var namespaces = new XmlNamespaceManager(new NameTable());
            string xmlns = (root.HasAttributes ? root.Attribute("xmlns")?.Value : null) ?? string.Empty;
            if (!string.IsNullOrEmpty(xmlns)) namespaces.AddNamespace("x", xmlns);

            foreach ((string xpath, string value) in metaMap)
                if (!string.IsNullOrWhiteSpace(value))
                {
                    XElement element = root.XPathSelectElement(xpath, namespaces);
                    if (element == null)
                    {
                        if (metadata == null)
                        {
                            metadata = root.XPathSelectElement("x:Metadata", namespaces);

                            if (metadata == null)
                            {
                                metadata = new XElement(XName.Get("Metadata", xmlns));
                                metadata.Add(Environment.NewLine);
                                root.Add(Environment.NewLine);
                                root.Add(metadata);
                                root.Add(Environment.NewLine);
                            }
                        }

                        metadata.Add(new XElement(XName.Get(xpath.Substring(xpath.LastIndexOf(':') + 1), xmlns), value));
                        metadata.Add(Environment.NewLine);
                    }
                    else
                    {
                        element.SetValue(value);
                    }
                }

            // ======================================== //

            XElement identity = root.XPathSelectElement("x:Metadata/x:Identity", namespaces);
            if (identity == null)
            {
                identity = new XElement(XName.Get("Identity", xmlns));
                metadata.Add(Environment.NewLine);
                metadata.Add(identity);
                metadata.Add(Environment.NewLine);
            }

            IEnumerable<(string, string)> identityMap = new (string, string)[]
            {
                ("Version", expand(manifest.Version.ToString(manifest.VersionFormat?? "C"))),
                ("Publisher", expand(manifest.Company))
            };
            foreach ((string name, string value) in identityMap)
                if (!string.IsNullOrWhiteSpace(value))
                {
                    XAttribute attribute = identity.Attribute(name);

                    if (attribute == null)
                    {
                        identity.Add(new XAttribute(name, value));
                    }
                    else
                    {
                        attribute.SetValue(value);
                    }
                }

            return document.ToString(SaveOptions.DisableFormatting);
        }
    }
}