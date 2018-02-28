<#
.SYNOPSIS
Updates all project/manifest files within the specified directory.

.DESCRIPTION
This cmdlet will update all project/manifest files within the specified directory using the provided [Manifest] object. When the -CommitChanges flag is present, all files modified by this cmdlet will be committed to GIT. Aslo when both the -TagCommit flag and -CommitChanges flag is present this cmdlet will tag the commit with the [Manifest] version number. Use the -Major and -Minor flags to increment the manifest version number.

The cmdlet returns a [PSCustomObject] containing a list of the files it modified and the [Manifest] object.

.PARAMETER Path
The root directory of your project(s).

.PARAMETER Manifest
A [Manifest] object.

.PARAMETER CommitMessage
The message to use when the -CommitChanges flag is present.

.PARAMETER CommitChanges
Determines whether to commit the modified file to source control (using Git).

.PARAMETER TagCommit
Determines whether the Git commit should be tagged with the current version number.

.OUTPUTS
[System.Management.Automation.PSCustomObject]

.EXAMPLE
"C:\manifest.json" | Get-NcrementManifest | Update-AllProjectManifests "C:\projects\new_idea" -Minor;
This example increments the project's version number.

.EXAMPLE
"C:\manifest.json" | Get-NcrementManifest | Update-AllProjectManifests "C:\projects\new_idea" -Major -Commit -Tag;
This example increments the project's version number and commits the changes to source control.

.LINK
Get-NcrementManifest

.LINK
Save-NcrementManifest
#>

function Update-NcrementProjectFile
{
	[CmdletBinding(SupportsShouldProcess)]
	Param(
		[Parameter(Mandatory, ValueFromPipeline, Position=1)]
		$Manifest,

		[Parameter(Position=0)]
		[Alias("root", "dir", "folder")]
		[string]$Path,

		[Alias('m', "msg", "message")]
		[string]$CommitMessage,

		[Alias('c', "commit")]
		[switch]$CommitChanges,

		[Alias('t', "tag")]
		[switch]$TagCommit
	)

	# Resolving the path.
	if ([string]::IsNullOrEmpty($Path))
	{ $Path = $PWD; }
	elseif (Test-Path $Path -PathType Leaf)
	{ $Path = Split-Path $Path -Parent; }
	elseif (-not (Test-Path $Path))
	{ throw "Could not find directory at '$Path'."; }

	# Update project files.
	$modifiedFiles = [System.Collections.ArrayList]::new();
	$modifiedFiles.Add($Manifest.Path);

	foreach ($result in @(
		(Edit-NetCoreProjectFile $Manifest $Path),
		(Edit-NetFrameworkProjectFile $Manifest $Path),
		(Edit-VSIXManifestFile $Manifest $Path)
	))
	{
		if ($result -ne $null)
		{
				foreach ($file in $result)
				{
					$modifiedFiles.Add($file);
					Write-Debug "'$($file.Replace($Path, '.'))' was modified.";
				}
		}
	}

	if ($CommitChanges)
	{
		try
		{
			Push-Location $Path;
			# Staging the modified files.
			foreach ($file in $modifiedFiles)
			{
				if ($PSCmdlet.ShouldProcess($file, "git add"))
				{
					&git add "$file" | Out-Null;
					Write-Debug "Staged '$($file.Replace($Path, '.'))'.";
				}
			}

			# Resolving the commit message.
			if ([string]::IsNullOrEmpty($CommitMessage))
			{ $CommitMessage = "Increment the version number to '$nextVersion'."; }
			else
			{ $CommitMessage = [string]::Format($CommitMessage, $nextVersion); }

			# Commiting files to source control.
			if ($PSCmdlet.ShouldProcess($Path, "git commit"))
			{
				&git commit -m $CommitMessage | Out-Null;
				if ($TagCommit) { &git tag v$nextVersion | Out-Null; }
				Write-Information "Committed modified project files to source control.";
			}
		}
		finally { Pop-Location; }
	}

	return New-Object PSObject -Property @{
		"Manifest"=$Manifest;
		"ModifiedFiles"=$modifiedFiles;
	};
}

Set-Alias -Name "n-update" -Value "Update-NcrementProjectFile";
Set-Alias -Name "Update-Project" -Value "Update-NcrementProjectFile";