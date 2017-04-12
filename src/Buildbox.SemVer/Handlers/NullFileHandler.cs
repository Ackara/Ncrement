namespace Ackara.Buildbox.SemVer.Handlers
{
    internal class NullFileHandler : IFileHandler
    {
        public System.Collections.Generic.IEnumerable< System.IO.FileInfo> FindTargets(string directory) => new System.IO.FileInfo[0];

        public void Update(System.IO.FileInfo path, VersionInfo version) { }
    }
}