using LibGit2Sharp;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Shouldly;
using System;
using System.IO;
using System.Linq;

namespace Acklann.Ncrement.Tests
{
    [TestClass]
    public class GitTest
    {
        private static string _repositoryPath;

        [ClassInitialize]
        public static void Initialize(TestContext context)
        {
            _repositoryPath = Path.Combine(Path.GetTempPath(), $"{nameof(Ncrement)}-repo".ToLower(), Guid.NewGuid().ToString());
            if (Directory.Exists(_repositoryPath)) Directory.Delete(_repositoryPath, recursive: true);
            Directory.CreateDirectory(_repositoryPath);
            Repository.Init(_repositoryPath);

            using (var repo = new Repository(_repositoryPath))
            {
                string readme = Path.Combine(_repositoryPath, "README.md");
                File.WriteAllText(readme, $"# {nameof(Ncrement)}\n\n");
                repo.Index.Add(Path.GetFileName(readme));
                repo.Index.Write();

                Signature author = new Signature("anon", "anon@example.com", DateTime.Now);
                repo.Commit("init", author, author);
                repo.CreateBranch("beta");
            }
        }

        [TestMethod]
        public void Can_return_current_branch()
        {
            Git.GetCurrentBranchName(_repositoryPath).ShouldBe("master");
        }

        [TestMethod]
        public void Can_add_file_to_source_control()
        {
            // Arrange
            string newFile1 = Path.Combine(_repositoryPath, "foo.ts");
            string newFile2 = Path.Combine(_repositoryPath, "bar.ts");

            // Act
            File.WriteAllText(newFile1, "class Foo { }");
            var case1 = Git.Stage(newFile1, _repositoryPath);

            File.WriteAllText(newFile2, "class Bar { }");
            var case2 = Git.StageAll(_repositoryPath);

            // Assert
            case1.ShouldBeTrue();
            case2.ShouldBeTrue();
        }

        [TestMethod]
        public void Can_commit_changes_to_source_control()
        {
            // Arrange
            var newFile = Path.Combine(_repositoryPath, "releaseNotes.md");

            // Act
            File.WriteAllText(newFile, "Version 19.3.8");
            Git.StageAll(_repositoryPath);
            var success = Git.Commit(_repositoryPath, "something good.");

            // Assert
            success.ShouldBeTrue();
        }

        [TestMethod]
        public void Can_resolve_git_path_from_file()
        {
            // Arrange
            string stagedFile = Directory.EnumerateFiles(_repositoryPath).First();

            // Act
            var result = Git.GetWorkingDirectory(stagedFile);

            // Assert
            result.ShouldBe(_repositoryPath);
        }
    }
}