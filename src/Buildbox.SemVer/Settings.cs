using Acklann.Buildbox.SemVer.Handlers;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text.RegularExpressions;

namespace Acklann.Buildbox.SemVer
{
    [JsonObject(semanticVersion)]
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
                Settings settings = Parse(content);
                settings.Filename = pathToSettingsFile;
                return settings;
            }
            else if (pathToSettingsFile == DefaultSettingsPath)
            {
                // Create Default Settings
                var settings = new Settings()
                {
                    Handlers = ((
                    from id in (new FileHandlerFactory().GetFileHandlerIds())
                    where id != nameof(NullFileHandler)
                    select id).ToArray()),
                    ShouldAddUnstagedFilesWhenCommitting = false,
                    ShouldCommitChanges = true,
                    ShouldTagCommit = true
                };
                settings.BranchToSuffixMap.Add("master", string.Empty);
                settings.BranchToSuffixMap.Add("*", "alpha");
                settings.Save();
                return settings;
            }
            else throw new FileNotFoundException($"cannot find '{pathToSettingsFile}'.", pathToSettingsFile);
        }

        public static Settings Parse(string json)
        {
            var root = JObject.Parse(json);
            JProperty semver = (
                from prop in root.Descendants()
                where prop.Type == JTokenType.Property && (prop as JProperty).Name.Equals(semanticVersion, StringComparison.CurrentCultureIgnoreCase)
                select prop as JProperty).FirstOrDefault();

            return (semver == null) ?
                JsonConvert.DeserializeObject<Settings>(json) :
                JsonConvert.DeserializeObject<Settings>(semver.Value.ToString());
        }

        private const string semanticVersion = "semanticVersion";

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
        public string Filename { get; private set; }

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

        public void Save(bool partial = false)
        {
            Save(Filename, partial);
        }

        public void Save(string path, bool partial = false)
        {
            string parentDir = Path.GetDirectoryName(path);
            if (!Directory.Exists(parentDir)) Directory.CreateDirectory(parentDir);

            if (partial)
            {
                string versionJson = JsonConvert.SerializeObject(Version, Formatting.Indented);
                string contents = File.ReadAllText(path);
                contents = Regex.Replace(contents, @"""version""\s*:\s*(?<body>{[^}]+})", delegate (Match match)
                {
                    string value = match.Value;
                    value = Regex.Replace(value, @"""major""\s*:\s*\d+", $"\"major\": {Version.Major}");
                    value = Regex.Replace(value, @"""minor""\s*:\s*\d+", $"\"minor\": {Version.Minor}");
                    value = Regex.Replace(value, @"""patch""\s*:\s*\d+", $"\"patch\": {Version.Patch}");

                    return value;
                });
                File.WriteAllText(path, contents);
            }
            else
            {
                string json = JsonConvert.SerializeObject(this, Formatting.Indented);
                File.WriteAllText(path, json);
            }
        }
    }
}