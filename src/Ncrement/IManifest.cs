using System.Collections.Generic;

namespace Acklann.Ncrement
{
    public interface IManifest
    {
        string Authors { get; set; }
        string Company { get; set; }
        string Copyright { get; set; }
        string Description { get; set; }
        
        string Icon { get; set; }
        string Id { get; set; }
        string License { get; set; }
        string Name { get; set; }
        string ReleaseNotes { get; set; }
        string Repository { get; set; }
        string Tags { get; set; }

        string VersionFormat { get; set; }
        string Website { get; set; }
    }
}