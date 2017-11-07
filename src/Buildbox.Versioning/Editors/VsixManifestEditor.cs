using System.IO;
using System.Xml;
using System.Xml.Linq;
using System.Xml.XPath;

namespace Acklann.Buildbox.Versioning.Editors
{
    public class VsixManifestEditor : IProjectEditor
    {
        public FileInfo[] FindProjectFile(string solutionDirectory)
        {
            return new DirectoryInfo(solutionDirectory).GetFiles("*.vsixmanifest", SearchOption.AllDirectories);
        }

        public void Update(Manifest manifest, params FileInfo[] projectFiles)
        {
            foreach (var file in projectFiles)
            {
                XDocument document;
                using (var reader = XmlReader.Create(file.FullName))
                {
                    string ns = "http://schemas.microsoft.com/developer/vsx-schema/2011";
                    var xmlns = new XmlNamespaceManager(reader.NameTable);
                    xmlns.AddNamespace("x", ns);

                    document = XDocument.Load(reader);
                    XElement metadata = document.XPathSelectElement("//x:Metadata", xmlns);
                    if (metadata != null)
                    {
                        XElement identity = metadata.XPathSelectElement("x:Identity", xmlns);
                        foreach (var arg in new(string AttributeName, string Value)[]
                        {
                            ("Version", manifest.Version.ToString()),
                            ("Publisher", manifest.Owner)
                        }) if (!string.IsNullOrEmpty(arg.Value))
                            {
                                XAttribute attribute = identity.Attribute(arg.AttributeName);
                                if (attribute == null)
                                {
                                    identity.Add(new XAttribute(arg.AttributeName, arg.Value));
                                }
                                else
                                {
                                    attribute.SetValue(arg.Value);
                                }
                            }

                        foreach (var arg in new(string ElementName, string Value)[]
                        {
                            ("ReleaseNotes", manifest.ReleaseNotes),
                            ("Description", manifest.Description),
                            ("License", manifest.LicenseUri),
                            ("DisplayName", manifest.Title),
                            ("Icon", manifest.IconUri),
                            ("Tags", manifest.Tags)
                        })
                        {
                            if (!string.IsNullOrEmpty(arg.Value))
                            {
                                XElement element = metadata.XPathSelectElement($"x:{arg.ElementName}", xmlns);
                                if (element == null)
                                {
                                    metadata.Add(new XElement(XName.Get(arg.ElementName, ns), arg.Value));
                                }
                                else
                                {
                                    element.SetValue(arg.Value);
                                }
                            }
                        }
                    }
                }
                using (var outStream = XmlWriter.Create(file.OpenWrite(), new XmlWriterSettings()
                {
                    Indent = true,
                    CloseOutput = true
                }))
                {
                    document.Save(outStream);
                }
            }
        }
    }
}