using Acklann.Ncrement.Extensions;
using System.Management.Automation;

namespace Acklann.Ncrement.Cmdlets
{
    /// <summary>
    /// <para type="synopsis">Creates a new [Manifest] object.</para>
    /// <para type="description">This cmdlet creates a new [Manifest] object.</para>
    /// </summary>
    /// <seealso cref="Acklann.Ncrement.Cmdlets.ManifestCmdletBase" />
    /// <example>
    /// <code>
    /// New-NcrementManifest | ConvertTo-Json | Out-File "C:\app\manifest.json";
    /// </code>
    /// <para>This example, creates a new [Manifest] and saves to a file.</para>
    /// </example>
    [OutputType(typeof(Manifest))]
    [Cmdlet(VerbsCommon.New, (nameof(Ncrement) + "Manifest"))]
    public class NewManifestCmdlet : ManifestCmdletBase
    {

        /// <summary>
        /// Processes the record.
        /// </summary>
        protected override void ProcessRecord()
        {
            WriteObject(Overwrite(Manifest.CreateTemplate()).ToPSObject());
        }
    }
}