function ConvertTo-NcrementVersionNumber
{
	Param(
		[Parameter(Mandatory, ValueFromPipeline)]
		$InputObject
	)

	$manifest = $InputObject;
	$path = ConvertTo-Path $InputObject;
	if ((-not [string]::IsNullOrEmpty($path)) -and (Test-Path $path -PathType Leaf))
	{
		$manifest = Get-Content $path | ConvertFrom-Json;
	}

	if ($manifest -ne $null)
	{
		return "$($manifest.version.major).$($manifest.version.minor).$($manifest.version.patch)";
	}
	else { Write-Error "The 'InputObject' cannot be null or empty."; }
}