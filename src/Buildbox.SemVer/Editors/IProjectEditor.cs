using System.IO;

namespace Acklann.Buildbox.SemVer.Editors
{
    public interface IProjectEditor
    {
        FileInfo[] FindProjectFile(string solutionDirectory);

        void Update(Manifest manifest, params FileInfo[] projectFiles);
    }
}