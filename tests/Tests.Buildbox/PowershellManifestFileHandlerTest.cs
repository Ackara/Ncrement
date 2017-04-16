using Ackara.Buildbox.SemVer;
using Ackara.Buildbox.SemVer.Handlers;
using ApprovalTests;
using ApprovalTests.Namers;
using ApprovalTests.Reporters;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Shouldly;
using System.IO;
using System.Linq;
using System.Reflection;

namespace Tests.Buildbox
{
    [TestClass]
    [UseApprovalSubdirectory(nameof(ApprovalTests))]
    [UseReporter(typeof(FileLauncherReporter), typeof(ClipboardReporter))]
    public class PowershellManifestFileHandlerTest
    {
        public TestContext TestContext { get; set; }

        [TestMethod]
        public void FindTagets_should_return_all_powershell_manifest_files()
        {
            // Arrange
            var sampleSolution = GetSampleSolutionDir();
            var sut = new PowershellManifestFileHandler();

            // Act
            var results = sut.FindTargets(sampleSolution).ToList();
            var invalidTargets = (
                from x in results
                where x.Extension != ".psd1"
                select x.Name);

            // Assert
            results.ShouldHaveSingleItem();
            invalidTargets.ShouldBeEmpty();
        }

        [TestMethod]
        public void Update_should_set_the_version_field_within_the_manifest_file()
        {
            // Arrange
            var version = new VersionInfo()
            {
                Major = 1,
                Minor = 2,
                Patch = 3,
                Suffix = "beta"
            };
            var solutionDir = GetSampleSolutionDir();
            var sut = new PowershellManifestFileHandler();

            // Act
            var sourceFile = sut.FindTargets(solutionDir).First();
            var sampleFile = Path.Combine(TestContext.DeploymentDirectory, $"{nameof(PowershellManifestFileHandler)}_{nameof(sut.Update)}_result.txt");
            sourceFile.CopyTo(sampleFile, overwrite: true);

            sut.Update(sampleFile, version);

            // Assert
            Approvals.VerifyFile(sampleFile);
        }

        private static string GetSampleSolutionDir()
        {
            string directory = Assembly.GetExecutingAssembly().Location;
            for (int i = 0; i < 3; i++)
            {
                directory = Path.GetDirectoryName(directory);
            }

            return Path.Combine(directory, "Samples", "semver");
        }
    }
}