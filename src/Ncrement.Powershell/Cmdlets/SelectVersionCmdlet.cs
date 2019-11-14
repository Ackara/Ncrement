using System;
using System.IO;
using System.Management.Automation;

namespace Acklann.Ncrement.Cmdlets
{
    /// <summary>
    /// <para type="synopsis"></para>
    /// </summary>
    /// <seealso cref="System.Management.Automation.Cmdlet" />
    [OutputType(typeof(string))]
    [Cmdlet(VerbsCommon.Select, (nameof(Ncrement) + "VersionNumber"), DefaultParameterSetName = nameof(String))]
    public class SelectVersionCmdlet : Cmdlet
    {
        [ValidateNotNull]
        [Parameter(Mandatory = true, ParameterSetName = nameof(Object))]
        public Manifest InputObject { get; set; }

        [ValidateNotNullOrEmpty]
        [Alias("Path", nameof(FileInfo.FullName))]
        [Parameter(Mandatory = true, ValueFromPipelineByPropertyName = true, ParameterSetName = nameof(String))]
        public string ManifestPath { get; set; }

        [Parameter]
        [ValidateNotNullOrEmpty]
        public string Format { get; set; }

        protected override void ProcessRecord()
        {
            Manifest manifest = (InputObject ?? Manifest.LoadFrom(ManifestPath));
            WriteObject(manifest.Version.ToString(Format ?? "G"));
        }
    }
}