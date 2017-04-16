using Ackara.Buildbox.SemVer.Handlers;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;

namespace Ackara.Buildbox.SemVer
{
    [JsonObject("semanticVersion")]
    public class Settings
    {
        #region Static Members

        public const string FILENAME = "semver.json";
        public static readonly string DefaultSettingsPath = Path.Combine(Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location), FILENAME);

        public static string FindSettingsFile()
        {
            string localSettings = Path.Combine(Environment.CurrentDirectory, FILENAME);
            return File.Exists(localSettings) ? localSettings : DefaultSettingsPath;
        }

        public static Settings Load()
        {
            return Load(FindSettingsFile());
        }

        public static Settings Load(string pathToSettingsFile)
        {
            if (File.Exists(pathToSettingsFile))
            {
                string content = File.ReadAllText(pathToSettingsFile);
                return JsonConvert.DeserializeObject<Settings>(content);
            }
            else if (pathToSettingsFile == DefaultSettingsPath)
            {
                // Create Default Settings
                var settings = new Settings()
                {
                    Handlers = (
                    from id in (new FileHandlerFactory().GetFileHandlerIds())
                    where id != nameof(NullFileHandler)
                    select id).ToArray(),
                    ShouldAddUnstagedFilesWhenCommitting = false,
                    ShouldCommitChanges = true,
                    ShouldTagCommit = true
                };
                settings.BranchToSuffixMap.Add("master", string.Empty);
                settings.BranchToSuffixMap.Add("*", "-alpha");
                settings.Save();
                return settings;
            }
            else throw new FileNotFoundException($"cannot find '{pathToSettingsFile}'.", pathToSettingsFile);
        }

        #endregion Static Members

        public Settings() : this(DefaultSettingsPath)
        {
        }

        public Settings(string pathToSettingFile)
        {
            Filename = pathToSettingFile;
            Handlers = new string[0];
            Version = new VersionInfo();
            BranchToSuffixMap = new Dictionary<string, string>();
        }

        [JsonIgnore]
        public readonly string Filename;

        [JsonProperty("version")]
        public VersionInfo Version { get; set; }

        [JsonProperty("targets")]
        public string[] Handlers { get; set; }

        [JsonProperty("branchSuffixMap")]
        public IDictionary<string, string> BranchToSuffixMap { get; set; }

        [JsonProperty("shouldCommitChanges")]
        public bool ShouldCommitChanges { get; set; }

        [JsonProperty("shouldTagCommit")]
        public bool ShouldTagCommit { get; set; }

        [JsonProperty("shouldAddAllUnstagedFilesWhenCommitting")]
        public bool ShouldAddUnstagedFilesWhenCommitting { get; set; }

        public void Save()
        {
            Save(Filename);
        }

        public void Save(string path)
        {
            string json = JsonConvert.SerializeObject(this, Formatting.Indented);
            string parentDir = Path.GetDirectoryName(path);
            if (!Directory.Exists(parentDir)) Directory.CreateDirectory(parentDir);

            File.WriteAllText(path, json);
        }
    }
}