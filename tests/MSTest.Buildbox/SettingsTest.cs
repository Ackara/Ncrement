using Acklann.Buildbox.SemVer;
using ApprovalTests;
using ApprovalTests.Namers;
using ApprovalTests.Reporters;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Shouldly;
using System;
using System.IO;

namespace MSTest.Buildbox
{
    [TestClass]
    [UseApprovalSubdirectory(nameof(ApprovalTests))]
    [UseReporter(typeof(DiffReporter), typeof(ClipboardReporter))]
    public class SettingsTest
    {
        public TestContext TestContext { get; set; }

        [TestMethod]
        public void Load_should_generate_a_default_settings_file_when_it_do_not_exist()
        {
            // Act
            if (File.Exists(Settings.DefaultSettingsPath))
            {
                File.Delete(Settings.DefaultSettingsPath);
            }

            var result = Settings.Load();
            bool settingsFileWasCreated = File.Exists(Settings.DefaultSettingsPath);

            // Assert
            result.ShouldNotBeNull();
            settingsFileWasCreated.ShouldBeTrue();
            Approvals.VerifyFile(Settings.DefaultSettingsPath);
        }

        [TestMethod]
        public void Load_should_deserialize_a_settings_file_when_passed()
        {
            // Arrange
            string pathToConfigFile = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "Samples", "semver", "config.json");

            // Act
            var results = Settings.Load(pathToConfigFile);

            // Assert
            results.ShouldNotBeNull();
            results.Version.Patch.ShouldBe(8);
            results.Version.Suffix.ShouldNotBeNullOrWhiteSpace();
        }

        [TestMethod]
        public void Load_should_deserialize_a_partial_settings_file_when_passed()
        {
            // Arrange
            string pathToSourceFile = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "Samples", "semver", "config-partial.json");
            string pathToConfigFile = Path.Combine(TestContext.DeploymentDirectory, "config-partial.json");
            File.Copy(pathToSourceFile, pathToConfigFile, overwrite: true);

            // Act
            var settingsFile = Settings.Load(pathToConfigFile);
            var contentsBeforeSave = File.ReadAllText(pathToConfigFile);
            settingsFile.Save(partial: true);
            var contentsAfterSave = File.ReadAllText(pathToConfigFile);

            // Assert
            settingsFile.ShouldNotBeNull();
            Approvals.VerifyJson(contentsAfterSave);
            contentsBeforeSave.ShouldBe(contentsAfterSave);
        }
    }
}