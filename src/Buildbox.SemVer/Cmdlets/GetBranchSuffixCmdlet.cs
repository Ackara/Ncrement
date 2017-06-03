using System.Management.Automation;

namespace Acklann.Buildbox.SemVer.Cmdlets
{
    [Cmdlet(VerbsCommon.Get, "BranchSuffix")]
    public sealed class GetBranchSuffixCmdlet : CmdletBase
    {
        [Alias("branch", "bn" , "key")]
        [Parameter(ValueFromPipeline = true, Position = 0)]
        public string BranchName { get; set; }

        protected override void ProcessRecord()
        {
            if (Config.BranchToSuffixMap.ContainsKey(BranchName))
            {
                WriteObject(Config.BranchToSuffixMap[BranchName]);
            }
            else if (Config.BranchToSuffixMap.ContainsKey("*"))
            {
                WriteObject(Config.BranchToSuffixMap["*"]);
            }
            else
            {
                WriteObject(string.Empty);
            }
        }
    }
}