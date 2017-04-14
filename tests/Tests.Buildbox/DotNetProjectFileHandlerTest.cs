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
    [UseReporter(typeof(DiffReporter), typeof(ClipboardReporter))]
    public class DotNetProjectFileHandlerTest
    {
        public TestContext TestContext { get; set; }

        [TestMethod]
        public void FindTagets_should_return_all_dotnet_project_assemblyInfo_files()
        {
            // Arrange
            var sampleSolution = GetSampleSolutionDir();
            var sut = new DotNetProjectFileHandler();

            // Act
            var results = sut.FindTargets(sampleSolution).ToList();
            var invalidFiles = from n in results
                               where n.Name.Equals("assemblyInfo.cs", System.StringComparison.CurrentCultureIgnoreCase) == false
                               select n;

            // Assert
            results.ShouldHaveSingleItem();
            invalidFiles.ShouldBeEmpty();
        }

        [TestMethod]
        public void Update_should_set_the_assembly_version_attributes_within_the_specified_file()
        {
            // Arrange
            var version = new VersionInfo()
            {
                Major = 1,
                Minor = 2,
                Patch = 3,
                ReleaseTag = "-beta"
            };
            var solutionDir = GetSampleSolutionDir();
            var sut = new DotNetProjectFileHandler();

            // Act
            var sourceFile = sut.FindTargets(solutionDir).First();
            var sampleFile = Path.Combine(TestContext.DeploymentDirectory, sourceFile.Name);
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