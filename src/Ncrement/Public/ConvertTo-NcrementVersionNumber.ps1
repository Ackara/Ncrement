<#
.SYNOPSIS
Returns a version number.

.DESCRIPTION
This cmdlet creates a version number from the specified input. The input can be a '.json' file or an object.

.PARAMETER InputObject
The file-path or instance of a [Manifest] object.

.PARAMETER CurrentBrach
The branch name of the current repository.
#>

function ConvertTo-NcrementVersionNumber
{
	Param(
		[ValidateNotNull()]
		[Parameter(Mandatory, ValueFromPipeline)]
		$InputObject,

		[string]$CurrentBranch = "*"
	)

	PROCESS
	{
		$manifest = $InputObject;
		$path = ConvertTo-Path $InputObject;
		if ((-not [string]::IsNullOrEmpty($path)) -and (Test-Path $path -PathType Leaf))
		{
			$manifest = Get-Content $path | ConvertFrom-Json;
		}

		if ($manifest -ne $null)
		{
			[string]$suffix = "";
			if (($manifest | Get-Member "branchSuffixMap"))
			{
				if ($manifest.branchSuffixMap | Get-Member $CurrentBranch) { $suffix = $manifest.branchSuffixMap.$CurrentBranch; }
				elseif ($manifest.branchSuffixMap | Get-Member "*") { $suffix = $manifest.branchSuffixMap."*"; }
			}

			$tag = "";
			if (-not [string]::IsNullOrEmpty($suffix)) { $tag = "-$suffix"; }

			return [PSCustomObject]@{
				"Suffix"=$suffix;
				"Version"="$($manifest.version.major).$($manifest.version.minor).$($manifest.version.patch)";
				"FullVersion"="$($manifest.version.major).$($manifest.version.minor).$($manifest.version.patch)$tag";
			};
		}
		else { Write-Error "The 'InputObject' cannot be null or empty."; }
	}
}