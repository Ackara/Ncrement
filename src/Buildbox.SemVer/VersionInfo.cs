using Newtonsoft.Json;

namespace Ackara.Buildbox.SemVer
{
    public class VersionInfo
    {
        [JsonProperty("major")]
        public int Major { get; set; }

        [JsonProperty("minor")]
        public int Minor { get; set; }

        [JsonProperty("patch")]
        public int Patch { get; set; }

        [JsonProperty("releaseTag")]
        public string ReleaseTag { get; set; } = "";

        public void IncrementMajor()
        {
            Major++;
            Minor = 0;
            Patch = 0;
        }

        public void IncrementMinor()
        {
            Minor++;
            Patch = 0;
        }

        public void IncrementPatch()
        {
            Patch++;
        }

        public override string ToString()
        {
            return ToString(withoutTag: false);
        }

        public string ToString(bool withoutTag)
        {
            string tag = (string.IsNullOrWhiteSpace(ReleaseTag) || withoutTag) ? string.Empty : ReleaseTag;
            return $"{Major}.{Minor}.{Patch}{tag}";
        }
    }
}