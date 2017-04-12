using System.Collections.Generic;
using System.IO;
using System.Text.RegularExpressions;

namespace Ackara.Buildbox.SemVer.Handlers
{
    [FileHandlerId("dotnet")]
    public class DotNetProjectFileHandler : IFileHandler
    {
        public DotNetProjectFileHandler()
        {
            _patterns = new Dictionary<string, Regex>()
            {
                {"",  new Regex(@"\[assembly:\s*AssemblyVersion\s*\(\s*""(?<version>(\d\.?)+(\*|-\w+)?)""\s*\)\s*\]") },
                {"file",  new Regex(@"\[assembly:\s*AssemblyFileVersion\s*\(\s*""(?<version>(\d\.?)+(\*|-\w+)?)""\s*\)\s*\]") },
                {informational,  new Regex(@"\[assembly:\s*AssemblyInformationalVersion\s*\(\s*""(?<version>(\d\.?)+(\*|-\w+)?)""\s*\)\s*\]") }
            };
        }

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

            foreach (var pattern in _patterns)
            {
                string version = $"{versionInfo.Major}.{versionInfo.Minor}.{versionInfo.Patch}";

                if (pattern.Key == informational)
                {
                    version = versionInfo.ToString();
                    if (pattern.Value.IsMatch(contents) == false)
                    {
                        string newLine = contents.EndsWith("\n") ? string.Empty : "\n";
                        contents += $"{newLine}[assembly: AssemblyInformationalVersion(\"{version}\")]";
                    }
                }
                else
                {
                    contents = pattern.Value.Replace(contents, evaluator: delegate (Match match)
                    {
                        return match.Value.Replace(match.Groups["version"].Value, version);
                    });
                }
            }

            File.WriteAllText(file.FullName, contents);
        }

        #region Private Members

        private const string informational = "informational";
        private readonly IDictionary<string, Regex> _patterns;

        #endregion Private Members
    }
}