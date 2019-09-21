using Acklann.Semver;
using System.Collections.Generic;

namespace Acklann.Ncrement
{
    public class Manifest
    {
        public Manifest()
        {
            Copyright = "Copyright {year} {owner} All Rights Reserved.";
            VersionFormat = "g";
        }

        public string ProductId { get; set; }
        public string ProductName { get; set; }
        public SemanticVersion Version { get; set; }
        public string VersionFormat { get; set; }
        public string Description { get; set; }

        public string Tags { get; set; }
        public string Website { get; set; }
        public string IconUri { get; set; }
        public string Repository { get; set; }
        public string ReleaseNotes { get; set; }

        public string Company { get; set; }
        public string Authors { get; set; }
        public string License { get; set; }
        public string Copyright { get; set; }

        public IList<string>[] Projects { get; set; }
    }
}