function Update-ProjectManifests()
{
	<#
	.SYNOPSIS
	This cmdlet updates all project files within a given directory.

	.DESCRIPTION
	This cmdlet will update all project files within a given directory using the provided [Acklann.Buildbox.Versioning.Manifest] instance. When the -CommitChanged flag is present, all files modified by the cmdlet will be committed to git. Aslo when both the -TagCommit flag and -CommitChanges flag is present the cmdlet will tag the commit with the current version number. Use the -Major and -Minor flags to increment the manifest version number.

	The cmdlet returns a [PSCustomObject] containing a list of the files it modified, the [Acklann.Buildbox.Versioning.Manifest] object and a boolean that determines whether the git operations were sucessful.

	.PARAMETER RootDirectory
	The root directory of your project(s).

	.PARAMETER Manifest
	A [Acklann.Buildbox.Versioning.Manifest] object.

	.PARAMETER CommitMessage
	The Git commit message to use when the -CommitChanges flag is present.

	.PARAMETER CommitChanges
	Determines whether to commit the modified file to source control.

	.PARAMETER TagCommit
	Determines whether the Git commit should be tagged with the current version number.
	
	.PARAMETER Major
	Determines whether the Major version number should be incremented.

	.PARAMETER Minor
	Determines whether the Minor version number should be incremented.

	.OUTPUTS
	System.Management.Automation.PSCustomObject

	.EXAMPLE
	"C:\manifest.json" | Get-BuildboxManifest | Update-ProjectManifests "C:\projects\new_idea" -Minor;
	This example increments the project's version number.

	.EXAMPLE
	"C:\manifest.json" | Get-BuildboxManifest | Update-ProjectManifests "C:\projects\new_idea" -Major -Commit -Tag;
	This example increments the project's version number and commits the changes to source control.

	.LINK
	Get-BuildboxManifest

	.LINK
	New-BuildboxManifest
	#>

	Param(
		[Alias('i', "in")]
		[Parameter(Mandatory, ValueFromPipeline, Position = 3)]
		[Acklann.Buildbox.Versioning.Manifest]$Manifest,

		[Alias('r', "dir")]
		[Parameter(Mandatory, Position = 1)]
		[string]$RootDirectory,

		[Alias('m', "msg")]
		[Parameter(Position = 2)]
		[string]$CommitMessage,

		[Alias('c', "commit")]
		[switch]$CommitChanges,
		
		[Alias('t', "tag")]
		[switch]$TagCommit,

		[switch]$Major,
		[switch]$Minor
	)

	$modifiedFiles = New-Object System.Collections.ArrayList;
	$changesWereCommitted = $false;

	# Increment version number
	$oldVersion = $Manifest.Version.ToString();
	$Manifest.Version.Increment($Major.IsPresent, $Minor.IsPresent);
	
	# Update all Powershell Manifests (.psd1) files.
	$powershellManifests = Get-ChildItem $RootDirectory -Recurse -Filter "*.psd1";
	if ($powershellManifests.Length -gt 0)
	{
		$powershellManifests | Update-PowershellManifest $Manifest;
	}
	foreach ($proj in $powershellManifests) { $modifiedFiles.Add($proj); }

	# Update all other projects.
	$factory = New-Object Acklann.Buildbox.Versioning.Editors.ProjectEditorFactory;
	$projectEditors = $factory.GetProjectEditors();
	foreach ($editor in $projectEditors)
	{
		$projectFiles = $editor.FindProjectFile($RootDirectory);
		$editor.Update($Manifest, $projectFiles);
		foreach ($proj in $projectFiles) { $modifiedFiles.Add($proj); }
	}

	$Manifest.Save();
	$modifiedFiles.Add((Get-Item $Manifest.FullPath));
	Write-Verbose "updated version number from $oldVersion to $($Manifest.Version)";

	# Commit changes to git repository
	$gitIsInstalled = Assert-GitIsInstalled;
	if (-not $gitIsInstalled)
	{
		Write-Warning "git is not installed on this machine or was not added to the 'PATH' enviroment variable.";
	}

	if ($CommitChanges.IsPresent -and $gitIsInstalled)
	{
		$message = "Update the project's version number to $($Manifest.Version).";
		if (-not [String]::IsNullOrEmpty($CommitMessage))
		{
			$message = $CommitMessage;
		}
		
		# Stage modified files to git
		foreach ($file in $modifiedFiles)
		{
			& git add $file.FullName;
			Write-Verbose "git add: '$($file.FullName.Replace($RootDirectory, '').Trim(' ', '/', '\'))' to repository.";
		}

		# Commit modified files
		& git commit -m"$message";
		Write-Verbose "git commit: $message";
		if ($TagCommit.IsPresent)
		{
			& git tag "v$($Manifest.Version)";
			Write-Verbose "git tag: v$($Manifest.Version)";
		}

		$changesWereCommitted = $true;
	}

	return New-Object PSCustomObject -Property @{
		"CommittedChanges"=$changesWereCommitted;
		"ModifiedFiles"=$modifiedFiles;
		"Manifest"=$Manifest;
	};
}