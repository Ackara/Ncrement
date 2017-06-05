using System.Collections.Generic;
using System.Management.Automation;

namespace Acklann.Buildbox.SemVer.Cmdlets
{
    public abstract class CmdletBase : Cmdlet
    {
        protected Settings Config;

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

        protected string GetReleaseTag(Git git)
        {
            if (Config.BranchToSuffixMap.Count == 0) return string.Empty;
            else try
                {
                    string branchName = git.GetCurrentBranch();
                    if (Config.BranchToSuffixMap.ContainsKey(branchName))
                    {
                        return Config.BranchToSuffixMap[branchName];
                    }
                    else if (Config.BranchToSuffixMap.ContainsKey("*"))
                    {
                        return Config.BranchToSuffixMap["*"];
                    }
                    else return null;
                }
                catch (KeyNotFoundException)
                {
                    return Config.Version.Suffix;
                }
        }
    }
}