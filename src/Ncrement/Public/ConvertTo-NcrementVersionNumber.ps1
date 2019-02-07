function ConvertTo-NcrementVersionNumber
{
	Param(
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

			return [PSCustomObject]@{
				"Suffix"=$suffix;
				"Version"="$($manifest.version.major).$($manifest.version.minor).$($manifest.version.patch)";
				"FullVersion"="$($manifest.version.major).$($manifest.version.minor).$($manifest.version.patch)$suffix";
			};
		}
		else { Write-Error "The 'InputObject' cannot be null or empty."; }
	}
}