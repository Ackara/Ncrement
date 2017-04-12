using Ackara.Buildbox.SemVer;
using ApprovalTests;
using ApprovalTests.Namers;
using ApprovalTests.Reporters;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Shouldly;
using System.IO;

namespace Tests.Buildbox
{
    [TestClass]
    [UseApprovalSubdirectory(nameof(ApprovalTests))]
    [UseReporter(typeof(FileLauncherReporter), typeof(ClipboardReporter))]
    public class GitTest
    {
        public static string MockRepo;

        [ClassInitialize]
        public static void Setup(TestContext context)
        {
            MockRepo = CreateSampleRepo();
        }

        [TestMethod]
        public void GetCurrentBranch_should_return_the_name_of_the_git_branch()
        {
            System.Diagnostics.Debug.WriteLine($"repo: {MockRepo}");

            // Act
            var branchName = new Git(MockRepo).GetCurrentBranch();

            // Assert
            branchName.ShouldBe("dev");
        }

        [TestMethod]
        public void Commit_should_commit_all_specified_files_to_the_repo()
        {
            System.Diagnostics.Debug.WriteLine($"repo: {MockRepo}");

            // Arrange
            var sampleFiles = new string[]
            {
                Path.Combine(MockRepo, "file2.txt"),
                Path.Combine(MockRepo, "file3.txt")
            };
            var sut = new Git(MockRepo);

            // Act
            foreach (var file in sampleFiles)
            {
                File.WriteAllText(file, nameof(Commit_should_commit_all_specified_files_to_the_repo));
            }
            sut.Add(sampleFiles);
            sut.Commit("if you're reading this the test passed\n\nAlso quotation marks (\") and backlashes (\\) are acceptable.");

            var output = Git.Execute("status", MockRepo);

            // Assert
            Approvals.Verify(output);
        }

        [TestMethod]
        public void CreateTag_should_create_a_git_tag()
        {
            // Arrange
            var localRepo = CreateSampleRepo();
            System.Diagnostics.Debug.WriteLine($"repo: {localRepo}");

            var sampleFiles = Path.Combine(localRepo, "file3.txt");
            var sut = new Git(localRepo);

            // Act
            File.WriteAllText(sampleFiles, nameof(CreateTag_should_create_a_git_tag));
            sut.Add();
            sut.Commit("if you're reading this the test passed");
            sut.CreateTag("v0.0.1");

            var output = Git.Execute("tag", localRepo);

            // Assert
            output.ShouldBe("v0.0.1");
        }

        #region Private Members

        private static string CreateSampleRepo()
        {
            string mockRepo = Path.Combine(Path.GetTempPath(), nameof(GitTest), Path.GetFileNameWithoutExtension(Path.GetTempFileName()));
            if (Directory.Exists(mockRepo))
            {
                foreach (var file in Directory.GetFiles(mockRepo)) File.Delete(file);
            }
            else Directory.CreateDirectory(mockRepo);

            string sampleFile = Path.Combine(mockRepo, "file1.txt");
            File.WriteAllText(sampleFile, "this file contains some content");

            Git.Execute("init", mockRepo);
            Git.Execute("add .", mockRepo);
            Git.Execute("commit -minit", mockRepo);
            Git.Execute("checkout -b dev", mockRepo);
            return mockRepo;
        }

        #endregion Private Members
    }
}