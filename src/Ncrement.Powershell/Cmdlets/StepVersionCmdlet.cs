using Acklann.Ncrement.Extensions;
using System.Management.Automation;

namespace Acklann.Ncrement.Cmdlets
{
    /// <summary>
    /// <para type="synopsis">Increment a [Manifest] object version number.</para>
    /// <para type="description">This cmdlet incrments a [Manifest] object's version number.</para>
    /// </summary>
    /// <seealso cref="System.Management.Automation.Cmdlet" />
    /// <example>
    /// <code>"C:\app\maifest.json" | Step-NcrementVersionNumber -Minor | ConvertTo-Json | Out-File "C:\app\manifest.json";</code>
    /// <para type="description">This example increments version number then saves it back to disk.</para>
    /// </example>
    [Cmdlet(VerbsCommon.Step, (nameof(Ncrement) + "VersionNumber"))]
    public class StepVersionCmdlet : Cmdlet
    {
        /// <summary>
        /// <para type="description">The file-path or instance of a [Manifest] object.</para>
        /// </summary>
        [ValidateNotNullOrEmpty]
        [Parameter(Mandatory = true, ValueFromPipeline = true)]
        public PSObject InputObject { get; set; }

        /// <summary>
        /// <para type="description">When present, the major version number will be incremented.</para>
        /// </summary>
        [Parameter]
        public SwitchParameter Major { get; set; }

        /// <summary>
        /// <para type="description">When present, the minor version number will be incremented.</para>
        /// </summary>
        [Parameter]
        public SwitchParameter Minor { get; set; }

        /// <summary>
        /// <para type="description">When present, the patch version number will be incremented.</para>
        /// </summary>
        [Parameter]
        public SwitchParameter Patch { get; set; }

        /// <summary>
        /// </summary>
        protected override void ProcessRecord()
        {
            InputObject.GetManifestInfo(out Manifest manifest, out string _);

            if (Major.IsPresent)
                manifest.Version = manifest.Version.NextMajor();
            else if (Minor.IsPresent)
                manifest.Version = manifest.Version.NextMinor();
            else if (Patch.IsPresent)
                manifest.Version = manifest.Version.NextPatch();

            WriteObject(manifest.ToPSObject());
        }
    }
}