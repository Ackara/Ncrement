using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;

namespace Acklann.Buildbox.Versioning
{
    [JsonObject(JName)]
    public class Manifest
    {
        #region Static Members

        public const string JName = "manifest";

        public static readonly string DefaultFilePath = Path.Combine(System.IO.Directory.GetCurrentDirectory(), "manifest.json");

        public static Manifest Parse(string json)
        {
            if (string.IsNullOrWhiteSpace(json)) throw new ArgumentNullException(nameof(json));
            else
            {
                var root = JObject.Parse(json);
                JProperty manifest = (from prop in root.Descendants()
                                      where prop.Type == JTokenType.Property && (prop as JProperty).Name.Equals(JName, StringComparison.CurrentCultureIgnoreCase)
                                      select prop as JProperty
                                      ).FirstOrDefault();

                return (manifest == null) ?
                    JsonConvert.DeserializeObject<Manifest>(json) :
                    JsonConvert.DeserializeObject<Manifest>(manifest.Value.ToString());
            }
        }

        public static Manifest Load(string filePath)
        {
            Manifest manifest = Parse(File.ReadAllText(filePath));
            manifest._filePath = filePath;
            return manifest;
        }

        public static bool TryLoad(string filePath, out Manifest manifest)
        {
            return TryLoad(filePath, out manifest, out Exception error);
        }

        public static bool TryLoad(string filePath, out Manifest manifest, out Exception error)
        {
            bool succeeded = false;
            manifest = null; error = null;
            try
            {
                manifest = Load(filePath);
                succeeded = true;
            }
            catch (Exception ex)
            {
                error = ex;
            }

            return succeeded;
        }

        #endregion Static Members

        public Manifest() : this(DefaultFilePath)
        {
        }

        public Manifest(string filePath)
        {
            _filePath = filePath;
            Version = new VersionInfo();
            BranchToSuffixMap = new Dictionary<string, string>()
            {
                { "master", "" },
                { "*", "beta" }
            };
        }

        [JsonIgnore]
        public string Directory
        {
            get { return Path.GetDirectoryName(Filename); }
        }

        [JsonIgnore]
        public string Filename
        {
            get { return Path.GetFileName(_filePath); }
        }

        [JsonIgnore]
        public string FullPath
        {
            get { return _filePath; }
        }

        [JsonProperty("title")]
        public string Title { get; set; }

        [JsonProperty("version")]
        public VersionInfo Version { get; set; }

        [JsonProperty("description")]
        public string Description { get; set; }

        [JsonProperty("authors")]
        public string Authors { get; set; }

        [JsonProperty("owner")]
        public string Owner { get; set; }

        [JsonProperty("projectUrl")]
        public string ProjectUrl { get; set; }

        [JsonProperty("iconUri")]
        public string IconUri { get; set; }

        [JsonProperty("licenseUri")]
        public string LicenseUri { get; set; }

        [JsonProperty("copyright")]
        public string Copyright { get; set; }

        [JsonProperty("tags")]
        public string Tags { get; set; }

        [JsonProperty("branchSuffixMap")]
        public IDictionary<string, string> BranchToSuffixMap { get; set; }

        public void AddTag(string tag)
        {
            Tags = string.Concat(Tags, ", ", tag.Trim(',', ' ', '\r', '\n', '\t'));
        }

        public string GetBranchSuffix(string branchName)
        {
            if (BranchToSuffixMap.ContainsKey(branchName))
            {
                return BranchToSuffixMap[branchName];
            }
            else if (BranchToSuffixMap.ContainsKey("*"))
            {
                return BranchToSuffixMap["*"];
            }
            else return string.Empty;
        }

        public void Save()
        {
            Save(_filePath);
        }

        public void Save(string filePath)
        {
            // Create directory is it donot exist
            string dir = Path.GetDirectoryName(filePath);
            if (!System.IO.Directory.Exists(dir)) System.IO.Directory.CreateDirectory(dir);
            
            string json = "";
            if (File.Exists(filePath))
            {
                // Determine if the manifest object is nested within the file.
                // if so locate the node and update it while leaving the rest of the file intact.
                json = File.ReadAllText(filePath);
                if (string.IsNullOrWhiteSpace(json) == false)
                {
                    var document = JObject.Parse(json);
                    JProperty manifest = (from prop in document.Descendants()
                                          where prop.Type == JTokenType.Property && (prop as JProperty).Name.Equals(JName, StringComparison.CurrentCultureIgnoreCase)
                                          select prop as JProperty
                                          ).FirstOrDefault();

                    if (manifest != null)
                    {
                        manifest.Value = JObject.Parse(JsonConvert.SerializeObject(this));
                        File.WriteAllText(filePath, document.ToString());
                        return;
                    }
                }
            }

            json = JsonConvert.SerializeObject(this);
            File.WriteAllText(filePath, json, System.Text.Encoding.UTF8);
        }

        public override string ToString()
        {
            return _filePath ?? string.Empty;
        }

        #region Private Members

        private string _filePath;

        #endregion Private Members
    }
}