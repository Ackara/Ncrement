using Acklann.Buildbox.Versioning;
using Acklann.Buildbox.Versioning.Editors;
using ApprovalTests;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using System.IO;
using System.Linq;

namespace MSTest.Buildbox.Tests
{
    [TestClass]
    public class ProjectEditorTest
    {
        [TestMethod]
        public void Update_should_edit_a_netstardard_project_file_metadata()
        {
            // Arrange
            var manifest = CreateManifest();
            var sut = new NetStandardProjectEditor();

            // Act
            string tempPath = Path.GetTempFileName();
            var projectFile = sut.FindProjectFile(TestDataDirectory.FullPath).First();
            projectFile.CopyTo(tempPath, overwrite: true);
            sut.Update(manifest, new FileInfo(tempPath));

            // Assert
            Approvals.VerifyXml(File.ReadAllText(tempPath));
        }

        [TestMethod]
        public void Update_should_edit_a_dotnet_project_file_metadata()
        {
            // Arrange
            var manifest = CreateManifest();
            var sut = new DotNetProjectEditor();

            // Act
            string tempPath = Path.Combine(Path.GetTempPath(), $"{nameof(Update_should_edit_a_dotnet_project_file_metadata)}.txt");
            var projectFile = sut.FindProjectFile(TestDataDirectory.FullPath).First();
            projectFile.CopyTo(tempPath, overwrite: true);
            sut.Update(manifest, new FileInfo(tempPath));

            // Assert
            Approvals.VerifyFile(tempPath);
        }

        [TestMethod]
        public void Update_should_edit_a_vsix_manifest_file()
        {
            // Arrange
            var manifest = CreateManifest();
            var sut = new VsixManifestEditor();

            // Act
            string tempPath = Path.Combine(Path.GetTempPath(), $"{nameof(Update_should_edit_a_vsix_manifest_file)}.xml");
            var projectFile = sut.FindProjectFile(TestDataDirectory.FullPath).First();
            projectFile.CopyTo(tempPath, overwrite: true);
            sut.Update(manifest, new FileInfo(tempPath));

            // Assert
            Approvals.VerifyFile(tempPath);
        }

        private static Manifest CreateManifest()
        {
            var manifest = new Manifest()
            {
                Title = "Buildbox",
                Version = new VersionInfo(1, 2, 3),
                Authors = "Seto Kiaba",
                Owner = "Kiaba Corp",
                Copyright = "All rights reserved by Me",
                Description = "This is for a automated test",
                ProjectUrl = "https://gihub.com/Ackara/Buildbox",
                IconUri = "https://example.com/icon/buildbox.png",
                LicenseUri = "https://example.com/buildbox/license.txt",
                Tags = "powershell, deploy, ci"
            };

            return manifest;
        }
    }
}