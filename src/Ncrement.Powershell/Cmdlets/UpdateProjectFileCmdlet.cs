using Acklann.Ncrement.Extensions;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Management.Automation;

namespace Acklann.Ncrement.Cmdlets
{
    /// <summary>
    /// <para type="synopsis">Updates a project file version number.</para>
    /// <para type="description">
    /// This cmdlet will modify a project file with the information in the specified [Manifest]
    /// object. If the project file passed is not known it will be ignored.
    /// </para>
    /// </summary>
    /// <seealso cref="Acklann.Ncrement.Cmdlets.ManifestCmdletBase" />
    /// <example>
    /// <code>
    ///Get-ChildItem -Filter "*.csproj" | Update-NcrementProjectFile $manifest -Commit;
    /// </code>
    /// <para>
    /// This example will update the project file version number then commit the changes to source control.
    /// </para>
    /// </example>
    [OutputType(typeof(string))]
    [Cmdlet(VerbsData.Update, (nameof(Ncrement) + "ProjectFile"), ConfirmImpact = ConfirmImpact.Medium, SupportsShouldProcess = true)]
    public class UpdateProjectFileCmdlet : ManifestCmdletBase
    {
        /// <summary>
        /// <para type="description">The file-path or instance of a [Manifest] object.</para>
        /// </summary>
        [ValidateNotNull]
        [Alias(nameof(Manifest))]
        [Parameter(Mandatory = true, Position = 1)]
        public PSObject InputObject { get; set; }

        /// <summary>
        /// <para type="description">The project file. If the file type is unknown it will be ignored.</para>
        /// </summary>
        [Alias(nameof(PathInfo.Path), nameof(FileInfo.FullName))]
        [Parameter(Mandatory = true, ValueFromPipeline = true, ValueFromPipelineByPropertyName = true)]
        public string ProjectFile { get; set; }

        /// <summary>
        /// <para type="description">The commit message.</para>
        /// </summary>
        [Parameter]
        [Alias("m", "msg")]
        [ValidateNotNullOrEmpty]
        public string Message { get; set; }

        /// <summary>
        /// <para type="description">
        /// When present, any files modified by this cmdlet will be committed to source control.
        /// </para>
        /// </summary>
        [Parameter]
        public SwitchParameter Commit { get; set; }

        /// <summary>
        /// <para type="description">When present, all files will be committed to source control.</para>
        /// </summary>
        [Parameter]
        public SwitchParameter CommitAll { get; set; }

        /// <summary>
        /// </summary>
        protected override void BeginProcessing()
        {
            InputObject.GetManifestInfo(out _manifest, out string _);
            Overwrite(_manifest);
        }

        /// <summary>
        /// </summary>
        protected override void ProcessRecord()
        {
            if (File.Exists(ProjectFile) == false) return;

            string repositoryPath = Git.GetWorkingDirectory(ProjectFile);
            _manifest.SetVersionFormat(Git.GetCurrentBranchName(repositoryPath));
            _repositories.Add(repositoryPath);

            IDictionary<string, string> tokens = ReplacementToken.Create();
            tokens.AddGitTokens(repositoryPath);
            tokens["item-name"] = Path.GetFileName(ProjectFile);
            tokens["item-basename"] = Path.GetFileNameWithoutExtension(ProjectFile);
            tokens["item-directory"] = Path.GetDirectoryName(ProjectFile);
            tokens["item-directory-name"] = Path.GetFileName(Path.GetDirectoryName(ProjectFile));

            if (ShouldProcess(ProjectFile))
            {
                File.WriteAllText(ProjectFile, Editor.UpdateProjectFile(ProjectFile, _manifest, tokens));
                if (Commit) Git.Stage(ProjectFile, repositoryPath);
            }

            WriteObject(ProjectFile);
        }

        /// <summary>
        /// </summary>
        protected override void EndProcessing()
        {
            if (Commit || CommitAll)
            {
                _commitMsg
                    .AppendLine($"Change the version number to '{_manifest.Version.ToString("C")}'")
                    .AppendLine();

                foreach (string folder in _repositories.Distinct())
                    if (ShouldProcess(folder, "git-commit"))
                    {
                        if (CommitAll) Git.StageAll(folder);
                        Git.Commit(folder, (Message ?? _commitMsg.ToString()));
                    }
            }
        }

        #region Backing Members

        private Manifest _manifest;
        private ICollection<string> _repositories = new List<string>();
        private readonly System.Text.StringBuilder _commitMsg = new System.Text.StringBuilder();

        #endregion Backing Members
    }
}