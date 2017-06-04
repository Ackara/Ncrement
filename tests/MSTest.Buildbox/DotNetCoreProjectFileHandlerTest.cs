using Acklann.Buildbox.SemVer;
using Acklann.Buildbox.SemVer.Handlers;
using ApprovalTests;
using ApprovalTests.Namers;
using ApprovalTests.Reporters;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Shouldly;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Xml.Linq;
using System.Xml.XPath;

namespace MSTest.Buildbox
{
    [TestClass]
    [UseReporter(typeof(DiffReporter), typeof(ClipboardReporter))]
    public class DotNetCoreProjectFileHandlerTest
    {
        public TestContext TestContext { get; set; }
        
        [TestMethod]
        public void FindTargets_should_return_all_dotnet_core_project_files()
        {
            // Arrange
            var sampleSolution = GetSampleSolutionDir();
            var sut = new DotNetCoreProjectFileHandler();

            // Act
            var results = sut.FindTargets(sampleSolution).ToList();
            var doc = XDocument.Load(results.First().OpenRead());
            var targetFramework = doc.XPathSelectElement("Project//TargetFramework").Value;

            // Assert
            results.ShouldHaveSingleItem();
            targetFramework.ShouldBe("netstandard1.4");
        }

        [TestMethod]
        public void Update_should_set_the_version_nodes_within_the_dotnet_core_project_file()
        {
            // Arrange
            var version = new VersionInfo()
            {
                Major = 1,
                Minor = 2,
                Patch = 3,
                Suffix = "-beta"
            };
            var solutionDir = GetSampleSolutionDir();
            var sut = new DotNetCoreProjectFileHandler();

            // Act
            var sourceFile = sut.FindTargets(solutionDir).First();
            var sampleFile = Path.Combine(TestContext.DeploymentDirectory, $"{nameof(DotNetCoreProjectFileHandlerTest)}_{nameof(sut.Update)}_result.xml");
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