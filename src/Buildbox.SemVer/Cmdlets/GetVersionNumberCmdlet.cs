using System.Management.Automation;

namespace Acklann.Buildbox.SemVer.Cmdlets
{
    [Cmdlet(VerbsCommon.Get, "VersionNumber")]
    public class GetVersionNumberCmdlet : Cmdlet
    {
        [Parameter()]
        public string ConfigFile { get; set; }

        protected override void BeginProcessing()
        {
            if (string.IsNullOrWhiteSpace(ConfigFile))
            {
                ConfigFile = Settings.FindSettingsFile();
            }
        }

        protected override void ProcessRecord()
        {
            var settings = Settings.Load(ConfigFile);
            WriteObject(settings.Version);
        }
    }
}