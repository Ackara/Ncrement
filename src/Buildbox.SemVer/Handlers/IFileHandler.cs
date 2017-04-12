using System.Collections.Generic;
using System.IO;

namespace Ackara.Buildbox.SemVer.Handlers
{
    public interface IFileHandler
    {
        IEnumerable<FileInfo> FindTargets(string directory);

        void Update(FileInfo file, VersionInfo versionInfo);
    }
}