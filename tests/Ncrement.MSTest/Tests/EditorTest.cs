using Acklann.Diffa;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Shouldly;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;

namespace Acklann.Ncrement.Tests
{
    [TestClass]
    //[Acklann.Diffa.Reporters.Reporter(typeof(Acklann.Diffa.Reporters.FileReporter), interrupt: false)]
    public class EditorTest
    {
        [DataTestMethod]
        [DynamicData(nameof(GetProjectFiles), DynamicDataSourceType.Method)]
        public void Can_update_project_file(string fileName)
        {
            // Arrange
            var projectFile = Sample.GetFile(fileName).FullName;
            var results = new StringBuilder();

            results.AppendHeader("BEFORE");
            results.AppendLine(File.ReadAllText(projectFile)).AppendLine();

            // Act
            var contents = Editor.UpdateProjectFile(projectFile, GetManifest());
            results.AppendHeader("AFTER");
            results.AppendLine(contents);

            // Assert
            contents.ShouldNotContain("xxx");
            Diff.Approve(results, Path.GetFileNameWithoutExtension(fileName));
        }

        [TestMethod]
        public void Can_replace_tokens()
        {
            // Arrange
            const string value = "changed", format = "value: {{0}}";

            var tokens = ReplacementToken.Create();
            var results = new List<string>();

            // Act
            foreach (var item in tokens.Keys)
            {
                results.Add(ReplacementToken.Expand(string.Format(format, value), tokens));
            }

            // Assert
            results.ShouldNotBeEmpty();
            results.ShouldAllBe(x => x == string.Format(format, x));
        }

        private static IEnumerable<object[]> GetProjectFiles()
        {
            var testFiles = (from x in Directory.EnumerateFiles(Path.Combine(Sample.DirectoryName, "projects"))
                             //where Path.GetExtension(x) == ".json"
                             select x);

            foreach (string path in testFiles) yield return new object[] { path };
        }

        private static Manifest GetManifest()
        {
            var manifest = new Manifest()
            {
                Id = "Acme.Ncrement",
                Version = "1.2.3",
                Name = "Ncrement",
                Description = "This is a useful package.",

                Tags = "awesome cool",
                Website = "https://acme.com",
                Repository = "https://acme.com/repo/ncrement.git",
                Icon = "http://cdn.acme.com/img/logo.png",
                ReleaseNotes = "https://acme.com/project/ncrement/notes",

                Company = "Acme",
                Authors = "Ackara",
                Copyright = "Copyright {year} {company} All Rights Reserved.",
                License = "MIT"
            };
            return manifest;
        }
    }
}