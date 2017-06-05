using System.Collections.Generic;
using System.IO;
using System.Text.RegularExpressions;

namespace Acklann.Buildbox.SemVer.Handlers
{
    public class DotNetProjectFileHandler : IFileHandler
    {
        public IEnumerable<FileInfo> FindTargets(string directory)
        {
            if (Directory.Exists(directory))
                return new DirectoryInfo(directory).GetFiles("assemblyInfo.cs", SearchOption.AllDirectories);
            else
                return new FileInfo[0];
        }

        public void Update(string path, VersionInfo versionInfo)
        {
            Update(new FileInfo(path), versionInfo);
        }

        public void Update(FileInfo file, VersionInfo versionInfo)
        {
            string contents = File.ReadAllText(file.FullName);
            var regex = new Regex(@"\[assembly:\s*Assembly\w*Version\s*\(\s*""(?<version>(\d\.?)+(\*|-\w+)?)""\s*\)\s*\]");

            contents = regex.Replace(contents, delegate (Match match)
            {
                return match.Value.Replace(match.Groups["version"].Value, versionInfo.ToString(withoutTag: true));
            });

            File.WriteAllText(file.FullName, contents);
        }
    }
}