using Ackara.Buildbox.SemVer;
using ApprovalTests;
using ApprovalTests.Namers;
using ApprovalTests.Reporters;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Shouldly;
using System;
using System.IO;

namespace Tests.Buildbox
{
    [TestClass]
    [UseApprovalSubdirectory(nameof(ApprovalTests))]
    [UseReporter(typeof(FileLauncherReporter), typeof(ClipboardReporter))]
    public class SettingsTest
    {
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
    }
}