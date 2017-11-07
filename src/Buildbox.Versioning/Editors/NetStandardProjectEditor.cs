using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Xml.Linq;
using System.Xml.XPath;

namespace Acklann.Buildbox.Versioning.Editors
{
    public sealed class NetStandardProjectEditor : IProjectEditor
    {
        public FileInfo[] FindProjectFile(string solutionDirectory)
        {
            IEnumerable<FileInfo> projectFiles = from path in Directory.GetFiles(solutionDirectory, "*.csproj", SearchOption.AllDirectories)
                                                 let xDoc = XDocument.Load(path)
                                                 where xDoc?.Root?.Attribute("Sdk")?.Value == "Microsoft.NET.Sdk"
                                                 select new FileInfo(path);

            return projectFiles.ToArray();
        }

        public void Update(Manifest manifest, params FileInfo[] projectFiles)
        {
            foreach (var file in projectFiles.Where(x => x?.Exists ?? false))
            {
                var document = XDocument.Load(file.FullName);
                foreach (var arg in new(string ElementName, string Value)[]
                {
                    ("Product", manifest.Title),
                    ("PackageId", manifest.PackageId),
                    ("AssemblyVersion", manifest.Version.ToString()),
                    ("PackageVersion", manifest.Version.ToString()),
                    ("Description", manifest.Description),
                    ("Authors", manifest.Authors),
                    ("Company", manifest.Owner),
                    ("PackageTags", manifest.Tags),
                    ("Copyright", manifest.Copyright),
                    ("PackageIconUrl", manifest.IconUri),
                    ("PackageProjectUrl", manifest.ProjectUrl),
                    ("PackageLicenseUrl", manifest.LicenseUri),
                    ("PackageReleaseNotes", manifest.ReleaseNotes),
                })
                {
                    XElement[] targetNodes = document.Root.XPathSelectElements($"//PropertyGroup/{arg.ElementName}").ToArray();
                    if (targetNodes.Length == 0)
                    {
                        XElement propertyGroup = document.XPathSelectElement("/Project/PropertyGroup[1]");
                        propertyGroup.Add(new XElement(arg.ElementName, arg.Value));
                    }
                    else foreach (var element in targetNodes)
                        {
                            element.SetValue(arg.Value);
                        }
                }

                using (var outStream = file.OpenWrite())
                {
                    document.Save(outStream);
                }
            }
        }
    }
}