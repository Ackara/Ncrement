function Update-ProjectFile
{
	[CmdletBinding(ConfirmImpact = "Medium", SupportsShouldProcess)]
	Param(
		[Parameter(Mandatory)]
		$Manifest,

		[Parameter(Mandatory, ValueFromPipeline)]
		$InputObject,

		[Alias('m', "Message")]
		[string]$CommitMessage,

		[switch]$Commit
	)

	BEGIN
	{
		[int]$filesModified = 0; [string]$cwd;
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
				$currentVersion = ConvertTo-NcrementVersionNumber $Manifest | Select-Object -ExpandProperty Version;
				if ([string]::IsNullOrWhiteSpace(($CommitMessage))) { $CommitMessage = "Update the version-number to '$currentVersion'."; }

				Push-Location $cwd;
				&git commit -m $CommitMessage | Out-Null;
				Write-Verbose "Committed $filesModified file(s) to git repository.";
			}
			finally { Pop-Location; }
		}
	}
}