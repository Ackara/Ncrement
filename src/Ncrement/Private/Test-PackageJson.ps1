function Test-PackageJson {
	Param(
		[Parameter(ValueFromPipeline)]
		$InputObject
	)

	$path = ConvertTo-Path $InputObject;
	if ($path -and ($path.EndsWith("package.json")))
	{
		try 
		{ 
			$json = Get-Content $path | ConvertFrom-Json;
			return [PSCustomObject]@{
				"Path"=$path;
				"Content"=$json;
			};
		}
		catch { return $false; }
	}

	return $false;
}