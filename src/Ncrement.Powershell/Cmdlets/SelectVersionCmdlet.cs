using Acklann.Ncrement.Extensions;
using System.Management.Automation;

namespace Acklann.Ncrement.Cmdlets
{
    /// <summary>
    /// <para type="synopsis">Select the version number from a manifest.</para>
    /// </summary>
    /// <seealso cref="System.Management.Automation.Cmdlet" />
    [OutputType(typeof(string))]
    [Cmdlet(VerbsCommon.Select, (nameof(Ncrement) + "VersionNumber"))]
    public class SelectVersionCmdlet : Cmdlet
    {
        /// <summary>
        /// <para type="description">The source control current branch.</para>
        /// </summary>
        [Parameter]
        [Alias("b", "Branch")]
        [ValidateNotNullOrEmpty]
        public string CurrentBranch { get; set; }

        /// <summary>
        /// <para type="description">The file-path or instance of a [Manifest] object.</para>
        /// </summary>
        [ValidateNotNull]
        [Parameter(Mandatory = true, ValueFromPipeline = true)]
        public PSObject InputObject { get; set; }

        /// <summary>
        /// <para type="description">The format string.</para>
        /// </summary>
        [Parameter]
        [ValidateNotNullOrEmpty]
        public string Format { get; set; }

        /// <summary>
        /// Processes the record.
        /// </summary>
        protected override void ProcessRecord()
        {
            InputObject.GetManifestInfo(out Manifest manifest, out string manifestPath);

            if (!string.IsNullOrEmpty(manifestPath))
            {
                string respositoryPath = Git.GetWorkingDirectory(manifestPath);
                manifest.SetVersionFormat(CurrentBranch ?? Git.GetCurrentBranchName(respositoryPath));
            }

            WriteObject(manifest.Version.ToString(Format ?? manifest.VersionFormat ?? "G"));
        }
    }
}