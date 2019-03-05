<#
.SYNOPSIS
Updates a project file version number.

.DESCRIPTION
This cmdlet will modify a project file with the information in the specified [Manifest] object. If the project file passed is not known it will be ignored.

.PARAMETER Manifest
The file-path or instance of a [Manifest] object.

.PARAMETER InputObject
The project file. If the file type is unknown it will be ignored.

.PARAMETER CommitMessage
The git commit message.

.PARAMETER Commit
When present, any files modified by this cmdlet will be committed to source control.

.EXAMPLE
Get-ChildItem -Filter "*.csproj" | Update-NcrementProjectFile $manifest -Commit;
This example will update the project file version number then commit the changes to source control.
#>

function Update-NcrementProjectFile
{
	[CmdletBinding(ConfirmImpact = "Medium", SupportsShouldProcess)]
	Param(
		[Parameter(Mandatory)]
		[ValidateNotNull()]
		$Manifest,

		[Parameter(Mandatory, ValueFromPipeline)]
		[ValidateNotNull()]
		$InputObject,

		[Alias('m', "Message")]
		[string]$CommitMessage,

		[Alias('c')]
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
				if ([string]::IsNullOrWhiteSpace(($CommitMessage))) { $CommitMessage = "Update the version-number to $currentVersion."; }

				Push-Location $cwd;
				&git commit -m $CommitMessage | Out-Null;
				Write-Verbose "Committed $filesModified file(s) to git repository.";
			}
			finally { Pop-Location; }
		}
	}
}