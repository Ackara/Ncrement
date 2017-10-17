using Acklann.Buildbox.SemVer;
using ApprovalTests;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Shouldly;
using System;
using System.IO;

namespace MSTest.Buildbox.Tests
{
    [TestClass]
    public class ManifestTest
    {
        [TestMethod]
        public void Save_should_write_the_manifest_object_to_an_empty_file()
        {
            // Arrange
            var sut = CreateManifest();

            // Act
            string tempPath = Path.GetTempFileName();
            sut.Save(tempPath);

            // Assert
            Approvals.VerifyJson(File.ReadAllText(tempPath));
        }

        [TestMethod]
        public void Save_should_write_the_manifest_object_to_an_existing_json_file()
        {
            // Arrange
            var sut = CreateManifest();

            // Act
            string tempPath = Path.GetTempFileName();
            TestDataDirectory.GetFile(TestFile.MIXED_MANIFEST).CopyTo(tempPath, overwrite: true);
            sut.Save(tempPath);

            // Assert
            Approvals.VerifyJson(File.ReadAllText(tempPath));
        }

        [TestMethod]
        public void Load_should_throw_exception_when_the_given_file_is_not_valid()
        {
            // Arrange
            string nonExistingFile = Path.Combine(Path.GetTempPath(), $"({DateTime.Now.Ticks}).json");

            // Act
            var succeeded = Manifest.TryLoad(nonExistingFile, out Manifest manifest, out Exception error);

            // Assert
            succeeded.ShouldBeFalse();
            error.ShouldNotBeNull();
        }

        [TestMethod]
        public void Load_should_deserialize_the_manifest_object_from_a_json_file()
        {
            // Arrange
            var sampleFile = TestDataDirectory.GetFile(TestFile.MANIFEST).FullName;

            // Act
            var succeeded = Manifest.TryLoad(sampleFile, out Manifest result);

            // Assert
            succeeded.ShouldBeTrue();
            result.Title.ShouldNotBeNullOrWhiteSpace();
            result.Authors.ShouldNotBeNullOrWhiteSpace();
            result.Owner.ShouldNotBeNullOrWhiteSpace();
            result.Description.ShouldNotBeNullOrWhiteSpace();
            result.BranchToSuffixMap.Count.ShouldBeGreaterThanOrEqualTo(2);
            result.Version.ToString().ShouldBe("1.2.3");
        }

        [TestMethod]
        public void Load_should_deserialize_the_manifest_object_from_a_file_whereby_it_is_nested_in_another_object()
        {
            // Arrange
            var sampleFile = TestDataDirectory.GetFile(TestFile.MIXED_MANIFEST).FullName;

            // Act
            var succeeded = Manifest.TryLoad(sampleFile, out Manifest result);

            // Assert
            succeeded.ShouldBeTrue();
            result.Copyright.ShouldNotBeNullOrWhiteSpace();
            result.ProjectUrl.ShouldNotBeNullOrWhiteSpace();
            result.LicenseUri.ShouldNotBeNullOrWhiteSpace();
            result.IconUri.ShouldNotBeNullOrWhiteSpace();
            result.BranchToSuffixMap.Count.ShouldBeGreaterThanOrEqualTo(2);
            result.Version.ToString().ShouldBe("2.4.8");
        }

        private static Manifest CreateManifest()
        {
            var manifest = new Manifest()
            {
                Title = "Buildbox",
                Version = new VersionInfo(1, 2, 3),
                Authors = "Ackara",
                Owner = "Ackara",
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