function Test-NetcoreProjectFile
{
	Param(
		[Parameter(ValueFromPipeline)]
		$InputObject
	)

	[bool]$accept = $false, [string]$path;
	if (Test-Path $InputObject -PathType Leaf)
	{
		$accept = $true;
		$path = $InputObject;
		if (($InputObject | Get-Member "FullName")) { $path = $InputObject.FullName; }
	}

	if ($accept -and ($path.EndsWith("proj")))
	{
		[xml]$doc = $null;
		try { $doc = Get-Content $path; } catch { return $false; }
		return &{ 
			try 
			{ 
				$foundMatch = ($doc.SelectSingleNode("//Project[@Sdk]") -ne $null);
				if ($foundMatch) { return $doc; } else { return $false; }
			} 
			catch { return $false; } 
		};
	}

	return $false;
}