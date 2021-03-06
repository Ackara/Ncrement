using Acklann.Diffa;
using Acklann.Semver;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Shouldly;
using System.IO;

namespace Acklann.Ncrement.Tests
{
    [TestClass]
    public class SerializationTest
    {
        [TestMethod]
        public void Can_serialize_json_manifest()
        {
            // Arrange
            var manifestPath = Path.Combine(Path.GetTempPath(), $"{nameof(Ncrement)}_test_temp.json".ToLowerInvariant());
            File.Copy(Sample.GetManifestJSON().FullName, manifestPath, overwrite: true);

            // Act
            var manifest = Manifest.LoadFrom(manifestPath);
            manifest.Save(manifestPath);
            var json = File.ReadAllText(manifestPath);

            // Assert
            manifest.ShouldNotBeNull();
            manifest.BranchVersionMap.ShouldNotBeEmpty();
            manifest.Version.ShouldBe(new SemanticVersion(0, 0, 3));

            json.ShouldNotBeNullOrEmpty();
            Diff.Approve(json, ".json");
        }
    }
}