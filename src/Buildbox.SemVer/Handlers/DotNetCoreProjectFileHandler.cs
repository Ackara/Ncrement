using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Xml.Linq;
using System.Xml.XPath;

namespace Ackara.Buildbox.SemVer.Handlers
{
    [FileHandlerId("dotnetcore")]
    public class DotNetCoreProjectFileHandler : IFileHandler
    {
        public IEnumerable<FileInfo> FindTargets(string directory)
        {
            if (Directory.Exists(directory))
            {
                foreach (var file in (new DirectoryInfo(directory).GetFiles("*.csproj", SearchOption.AllDirectories)))
                {
                    var csproj = XDocument.Parse(File.ReadAllText(file.FullName));
                    var profiles = (
                        from x in csproj.XPathSelectElements("Project//TargetFramework")
                        where
                            x.Value.Contains("netstandard")
                            || x.Value.Contains("netcoreapp")
                        select x.Value);

                    // if not empty
                    if (profiles.Count() > 0) yield return file;
                }
            }
        }

        public void Update(string path, VersionInfo versionInfo)
        {
            Update(new FileInfo(path), versionInfo);
        }

        public void Update(FileInfo file, VersionInfo versionInfo)
        {
            var csproj = XDocument.Parse(File.ReadAllText(file.FullName));
            foreach (var expression in new string[] { "Project//Version", "Project//FileVersion", "Project//AssemblyVersion" })
            {
                XElement element = csproj.XPathSelectElement(expression);
                string nodeName = expression.Split(new char[] { '/' }, StringSplitOptions.RemoveEmptyEntries).Last();
                string version = versionInfo.ToString(withoutTag: true);

                if (element == null)
                    csproj.XPathSelectElement("Project/PropertyGroup").Add(new XElement(nodeName, version));
                else
                    element.Value = version;
            }
            csproj.Save(file.FullName);
        }
    }
}