using System.Management.Automation;

namespace Acklann.Buildbox.SemVer.Cmdlets
{
    [Cmdlet(VerbsCommon.Get, "BranchSuffix")]
    public sealed class GetBranchSuffixCmdlet : Cmdlet
    {
        [Parameter(Position = 2)]
        [Alias(new string[] { "config", "settings", "c" })]
        public string ConfigFile { get; set; }

        [Alias("branch", "bn", "key")]
        [Parameter(ValueFromPipeline = true, Position = 1)]
        public string BranchName { get; set; }

        protected override void BeginProcessing()
        {
            if (string.IsNullOrWhiteSpace(ConfigFile)) ConfigFile = Settings.FindSettingsFile();
            _config = Settings.Load(ConfigFile);
        }

        protected override void ProcessRecord()
        {
            if (_config.BranchToSuffixMap.ContainsKey(BranchName))
            {
                WriteObject(_config.BranchToSuffixMap[BranchName]);
            }
            else if (_config.BranchToSuffixMap.ContainsKey("*"))
            {
                WriteObject(_config.BranchToSuffixMap["*"]);
            }
            else
            {
                WriteObject(null);
            }
        }

        protected override void EndProcessing()
        {
            _config.Save(partial: true);
        }

        #region Private Members

        private Settings _config;

        #endregion Private Members
    }
}