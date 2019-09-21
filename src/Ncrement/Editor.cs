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

            throw new NotSupportedException($"'ext' files are not supported as yet.");
        }

        public static string UpdateDotnetProjectFile(string filePath, Manifest manifest, IDictionary<string, string> tokens)
        {
            if (!File.Exists(filePath)) throw new FileNotFoundException($"Could not find file at '{filePath}'.");
            if (manifest == null) throw new ArgumentNullException(nameof(manifest));

            // documentation: https://docs.microsoft.com/en-us/dotnet/core/tools/csproj#nuget-metadata-properties
            string expand(string input) => ReplacementToken.Expand(input, tokens);
            IEnumerable<(string, string)> map = new (string, string)[]
            {
                ("PackageId", expand(manifest.ProductId)),
                ("Version", expand(manifest.Version.ToString(manifest.VersionFormat))),
                ("Title", expand(manifest.ProductName)),
                ("Description", expand(manifest.Description)),

                ("RepositoryUrl", expand(manifest.Repository)),
                ("PackageProjectUrl", expand(manifest.Website)),
                ("PackageIconUrl", expand(manifest.IconUri)),
                ("PackageTags", expand(manifest.Tags)),
                ("PackageReleaseNotes", expand(manifest.ReleaseNotes)),

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
    }
}