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
    public class StepVersion : Cmdlet
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
            Manifest Manifest = InputObject.ToManifest();

            if (Major.IsPresent)
                Manifest.Version = Manifest.Version.NextMajor();
            else if (Minor.IsPresent)
                Manifest.Version = Manifest.Version.NextMinor();
            else
                Manifest.Version = Manifest.Version.NextPatch();

            WriteObject(Manifest);
        }
    }
}