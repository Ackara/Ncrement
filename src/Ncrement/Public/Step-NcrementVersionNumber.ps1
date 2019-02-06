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
		try { if (Test-Path $path -PathType Leaf -ErrorAction SilentlyContinue) { $manifest = Get-Content $path | ConvertFrom-Json; } } catch { }
		if ($InputObject | Get-Member "version") { $manifest = $InputObject; }

		if ($manifest -ne $null)
		{
			if ($Major)
			{
				$manifest.version.major++;
				$manifest.version.minor = 0;
				$manifest.version.patch = 0;
			}
			elseif ($Minor)
			{
				$manifest.version.minor++;
				$manifest.version.patch = 0;
			}
			else
			{
				$manifest.version.patch++;
			}

			return $manifest;
		}
	}
}