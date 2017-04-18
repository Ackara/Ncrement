using System.Management.Automation;

namespace Ackara.Buildbox.SemVer.Cmdlets
{
    public abstract class CmdletBase : Cmdlet
    {
        [Parameter]
        [Alias(new string[] { "break", "b" })]
        public SwitchParameter Major { get; set; }

        [Parameter]
        [Alias(new string[] { "feature", "f" })]
        public SwitchParameter Minor { get; set; }

        [Parameter]
        [Alias(new string[] { "fix", "p" })]
        public SwitchParameter Patch { get; set; }

        [Parameter]
        [Alias(new string[] { "config", "settings", "c" })]
        public string ConfigFile { get; set; }

        protected Settings Config;

        protected override void BeginProcessing()
        {
            if (string.IsNullOrWhiteSpace(ConfigFile)) ConfigFile = Settings.FindSettingsFile();
            Config = Settings.Load(ConfigFile);

            if (Major.IsPresent)
                Config.Version.IncrementMajor();
            else if (Minor.IsPresent)
                Config.Version.IncrementMinor();
            else if (Patch.IsPresent)
                Config.Version.IncrementPatch();
        }

        protected override void EndProcessing()
        {
            Config.Save(partial: true);
        }

        protected override void StopProcessing()
        {
            EndProcessing();
        }
    }
}