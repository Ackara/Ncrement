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
	Param(
		[Parameter(Mandatory, ValueFromPipeline)]
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

		if ($InputObject | Get-Member "version") { $manifest = $InputObject; }

		if ($manifest -ne $null)
		{
			if ($Major)
			{
				$manifest.version.major = $manifest.version.major + 1;
				$manifest.version.minor = 0;
				$manifest.version.patch = 0;
			}
			elseif ($Minor)
			{
				$manifest.version.minor = $manifest.version.minor + 1;
				$manifest.version.patch = 0;
			}
			else
			{
				$manifest.version.patch = $manifest.version.patch + 1;
			}

			return $manifest;
		}
	}
}