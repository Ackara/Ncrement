﻿function Update-ProjectFile
{
	[CmdletBinding(ConfirmImpact = "Medium", SupportsShouldProcess)]
	Param(
		[Parameter(Mandatory)]
		$Manifest,

		[Parameter(Mandatory, ValueFromPipeline)]
		$InputObject,

		[Alias('m', "Message")]
		[string]$CommitMessage,

		[switch]$Commit,

		[Alias("Break")]
		[switch]$Major,

		[Alias("Feature")]
		[switch]$Minor,

		[Alias("Fix")]
		[switch]$Patch
	)

	BEGIN
	{
		[int]$filesModified = 0; [string]$cwd;
		$currentVersion = ConvertTo-NcrementVersionNumber $Manifest;
		$Manifest = Step-NcrementVersionNumber $Manifest -Major:$Major -Minor:$Minor -Patch:$Patch;
		$nextVersion = ConvertTo-NcrementVersionNumber $Manifest;
		if ([string]::IsNullOrWhiteSpace(($CommitMessage)))
		{
			$CommitMessage = "Update the version-number from '$currentVersion' to '$nextVersion'.";
		}
	}

	PROCESS
	{
		$stagedFile = $InputObject | Edit-NetcoreProjectFile -Manifest $Manifest | Add-GitFile -Commit:$Commit;
		if ($stagedFile)
		{
			$filesModified++;
			$cwd = Split-Path $stagedFile -Parent;
			return $InputObject;
		}

		$stagedFile = $InputObject | Edit-NetFrameworkProjectFile -Manifest $Manifest | Add-GitFile -Commit:$Commit;
		if ($stagedFile)
		{
			$filesModified++;
			$cwd = Split-Path $stagedFile -Parent;
			return Get-Item $stagedFile;
		}

		$stagedFile = $InputObject | Edit-VSIXManifest -Manifest $Manifest | Add-GitFile -Commit:$Commit;
		if ($stagedFile)
		{
			$filesModified++;
			$cwd = Split-Path $stagedFile -Parent;
			return $InputObject;
		}

		$stagedFile = $InputObject | Edit-VSIXManifest -Manifest $Manifest | Add-GitFile -Commit:$Commit;
		if ($stagedFile)
		{
			$filesModified++;
			$cwd = Split-Path $stagedFile -Parent;
			return $InputObject;
		}

		$stagedFile = $InputObject | Edit-PackageJson -Manifest $Manifest | Add-GitFile -Commit:$Commit;
		if ($stagedFile)
		{
			$filesModified++;
			$cwd = Split-Path $stagedFile -Parent;
			return $InputObject;
		}

		$stagedFile = $InputObject | Edit-PowershellManifest -Manifest $Manifest | Add-GitFile -Commit:$Commit;
		if ($stagedFile)
		{
			$filesModified++;
			$cwd = Split-Path $stagedFile -Parent;
			return $InputObject;
		}
	}

	END
	{
		if ($Commit -and ($filesModified -gt 0) -and (Test-Git) -and $PSCmdlet.ShouldProcess($cwd, "git-commit"))
		{
			try
			{
				Push-Location $cwd;
				&git commit -m $CommitMessage | Out-Null;
				Write-Verbose "Committed $filesModified file(s) to git repository.";
			}
			finally { Pop-Location; }
		}
	}
}