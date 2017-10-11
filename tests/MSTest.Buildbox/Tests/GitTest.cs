using Acklann.Buildbox.SemVer;
using ApprovalTests;
using ApprovalTests.Namers;
using ApprovalTests.Reporters;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Shouldly;
using System.IO;

namespace MSTest.Buildbox.Tests
{
    [TestClass]
    public class GitTest
    {
        public static string MockRepository;

        [ClassInitialize]
        public static void Setup(TestContext context)
        {
            MockRepository = CreateSampleRepository();
        }

        [TestMethod]
        public void GetCurrentBranch_should_return_the_name_of_the_git_branch()
        {
            System.Diagnostics.Debug.WriteLine($"repo: {MockRepository}");

            // Act
            var branchName = new Git(MockRepository).GetCurrentBranch();

            // Assert
            branchName.ShouldBe("dev");
        }

        [TestMethod]
        public void Commit_should_commit_all_specified_files_to_the_repository()
        {
            System.Diagnostics.Debug.WriteLine($"repo: {MockRepository}");

            // Arrange
            var sampleFiles = new string[]
            {
                Path.Combine(MockRepository, "file2.txt"),
                Path.Combine(MockRepository, "file3.txt")
            };
            var sut = new Git(MockRepository);

            // Act
            foreach (var file in sampleFiles)
            {
                File.WriteAllText(file, nameof(Commit_should_commit_all_specified_files_to_the_repository));
            }
            sut.Add(sampleFiles);
            sut.Commit("if you're reading this the test passed\n\nAlso quotation marks (\") and backlashes (\\) are acceptable.");

            var output = Git.Execute("status", MockRepository);

            // Assert
            Approvals.Verify(output);
        }

        [TestMethod]
        public void CreateTag_should_create_a_git_tag()
        {
            // Arrange
            var repository = CreateSampleRepository();
            System.Diagnostics.Debug.WriteLine($"repo: {repository}");

            var sampleFiles = Path.Combine(repository, "file3.txt");
            var sut = new Git(repository);

            // Act
            File.WriteAllText(sampleFiles, nameof(CreateTag_should_create_a_git_tag));
            sut.Add();
            sut.Commit("if you're reading this the test passed");
            sut.Tag("v0.0.1");

            var output = Git.Execute("tag", repository);

            // Assert
            output.ShouldBe("v0.0.1");
        }

        #region Private Members

        private static string CreateSampleRepository()
        {
            string repository = Path.Combine(Path.GetTempPath(), nameof(GitTest), Path.GetFileNameWithoutExtension(Path.GetTempFileName()));
            if (Directory.Exists(repository))
            {
                foreach (var file in Directory.GetFiles(repository)) File.Delete(file);
            }
            else Directory.CreateDirectory(repository);

            string sampleFile = Path.Combine(repository, "file1.txt");
            File.WriteAllText(sampleFile, "this file contains some content");

            Git.Execute("init", repository);
            Git.Execute("add .", repository);
            Git.Execute("commit -minit", repository);
            Git.Execute("checkout -b dev", repository);
            return repository;
        }

        #endregion Private Members
    }
}