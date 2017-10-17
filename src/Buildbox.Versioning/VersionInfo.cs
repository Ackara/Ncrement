using Newtonsoft.Json;

namespace Acklann.Buildbox.Versioning
{
    public class VersionInfo
    {
        public VersionInfo() : this(1, 0, 0)
        {
        }

        public VersionInfo(int major, int minor, int patch)
        {
            Major = major;
            Minor = minor;
            Patch = patch;
        }

        [JsonProperty("major")]
        public int Major { get; set; }

        [JsonProperty("minor")]
        public int Minor { get; set; }

        [JsonProperty("patch")]
        public int Patch { get; set; }

        [JsonIgnore]
        public string Suffix { get; set; }

        public void IncrementMajor(int? major = null)
        {
            Major = major ?? ++Major;
            Minor = 0;
            Patch = 0;
        }

        public void IncrementMinor(int? minor = null)
        {
            Minor = minor ?? ++Minor;
            Patch = 0;
        }

        public void IncrementPatch(int? patch = null)
        {
            Patch = patch ?? ++Patch;
        }

        public void Increment(bool major = false, bool minor = false)
        {
            if (major) IncrementMajor();
            else if (minor) IncrementMinor();
            else IncrementPatch();
        }

        public override string ToString()
        {
            return $"{Major}.{Minor}.{Patch}";
        }

        public string ToString(bool withSuffix, char seperator = '-')
        {
            return withSuffix ? $"{Major}.{Minor}.{Patch}{seperator}{Suffix}" : ToString();
        }
    }
}