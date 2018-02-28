namespace Ncrement
{
    public class Manifest
    {
        public Manifest()
        {
            Id = System.Guid.NewGuid().ToString();
            Version = new Version { Major = 0, Minor = 0, Patch = 1, Suffix = "" };
            BranchSuffixMap = new System.Collections.Generic.Dictionary<string, string>
            {
                {"master", "" },
                {"*", "alpha" }
            };
        }

        public string Path { get; set; }

        public string Id { get; set; }
        public Version Version { get; set; }

        public string Name { get; set; }
        public string Summary { get; set; }
        public string Description { get; set; }

        public string Author { get; set; }
        public string Company { get; set; }
        public string License { get; set; }
        public string Copyright { get; set; }

        public string Website { get; set; }
        public string RespositoryUrl { get; set; }
        public string ReleaseNotes { get; set; }
        public string Icon { get; set; }

        public System.Collections.Generic.Dictionary<string, string> BranchSuffixMap { get; set; }
    }

    public struct Version
    {
        public int Major { get; set; }

        public int Minor { get; set; }

        public int Patch { get; set; }

        public string Suffix { get; set; }
    }
}