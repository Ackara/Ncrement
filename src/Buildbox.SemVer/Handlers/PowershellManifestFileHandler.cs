using System.Collections.Generic;
using System.IO;
using System.Text.RegularExpressions;

namespace Ackara.Buildbox.SemVer.Handlers
{
    [FileHandlerId("powershell")]
    public class PowershellManifestFileHandler : IFileHandler
    {
        public IEnumerable<FileInfo> FindTargets(string directory)
        {
            if (Directory.Exists(directory))
                return new DirectoryInfo(directory).GetFiles("*.psd1", SearchOption.AllDirectories);
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
            contents = Regex.Replace(
                input: contents,
                pattern: @"ModuleVersion\s*=\s*('|"")(?<version>(\d\.?)+(\*|-\w+)?)('|"")",
                replacement: $"ModuleVersion = '{versionInfo.ToString(withoutTag: true)}'");

            File.WriteAllText(file.FullName, contents);
        }
    }
}