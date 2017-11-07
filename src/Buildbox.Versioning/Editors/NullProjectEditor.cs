using System.IO;

namespace Acklann.Buildbox.Versioning.Editors
{
    public class NullProjectEditor : IProjectEditor
    {
        public FileInfo[] FindProjectFile(string solutionDirectory)
        {
            return new FileInfo[0];
        }

        public void Update(Manifest manifest, params FileInfo[] projectFiles)
        {
        }
    }
}