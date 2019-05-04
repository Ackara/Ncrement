<#
.SYNOPSIS
Increment a [Manifest] object version number.

.DESCRIPTION
This cmdlet incrments a [Manifest] object's version number.

.PARAMETER InputObject
The file-path or instance of a [Manifest] object.

.PARAMETER Major
When present, the major version number will be incremented.

.PARAMETER Minor
When present, the minor version number will be incremented.

.PARAMETER Patch
When present, the patch version number will be incremented.

.EXAMPLE
"C:\app\maifest.json" | Step-NcrementVersionNumber -Minor | ConvertTo-Json | Out-File "C:\app\manifest.json";
This example increments version number then saves it back to disk.
#>

function Step-NcrementVersionNumber
{
	[CmdletBinding()]
	Param(
		[ValidateNotNull()]
		[Alias("Path", "FullName")]
		[Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		$InputObject,

		[switch]$Major,

		[switch]$Minor,

		[switch]$Patch
	)

	PROCESS
	{
		[string]$path = ConvertTo-Path $InputObject;
		
		$manifest = $null;
		if ((-not [string]::IsNullOrEmpty($path)) -and (Test-Path $path -PathType Leaf))
		{
			$manifest = Get-Content $path | ConvertFrom-Json;
		}

		if ($InputObject | Get-Member "Version") { $manifest = $InputObject; }

		if ($manifest -ne $null)
		{
			$oldVersion = "$($manifest.Version.Major).$($manifest.Version.Minor).$($manifest.Version.Patch)";
			if ($Major)
			{
				$manifest.Version.Major = $manifest.Version.Major + 1;
				$manifest.Version.Minor = 0;
				$manifest.Version.Patch = 0;
			}
			elseif ($Minor)
			{
				$manifest.Version.Minor = $manifest.Version.Minor + 1;
				$manifest.Version.Patch = 0;
			}
			else
			{
				$manifest.Version.Patch = $manifest.Version.Patch + 1;
			}
			$newVersion = "$($manifest.Version.Major).$($manifest.Version.Minor).$($manifest.Version.Patch)";

			Write-Verbose "Incremented version-number from $oldVersion to $newVersion";
			return $manifest;
		}
	}
}