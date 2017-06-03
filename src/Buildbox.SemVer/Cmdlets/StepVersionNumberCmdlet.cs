using System.Management.Automation;

namespace Acklann.Buildbox.SemVer.Cmdlets
{
    [Cmdlet(VerbsCommon.Step, "VersionNumber")]
    public class StepVersionNumberCmdlet : CmdletBase
    {
        protected override void ProcessRecord() => WriteObject(Config.Version);
    }
}