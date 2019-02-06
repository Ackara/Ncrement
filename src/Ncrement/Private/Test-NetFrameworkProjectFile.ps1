function Test-NetFrameworkProjectFile
{
	Param(
		[Parameter(ValueFromPipeline)]
		$InputObject
	)

	[bool]$accept = $false;
	$path = ConvertTo-Path $InputObject;
	
	if ($path -and ($path.EndsWith("proj")))
	{
		[xml]$doc = $null;
		try { $doc = Get-Content $path; } catch { return $false; }
		$ns = [System.Xml.XmlNamespaceManager]::new($doc.NameTable);
		$ns.AddNamespace("x", "http://schemas.microsoft.com/developer/msbuild/2003");

		try 
		{ 
			$valid = ($doc.SelectSingleNode("//x:Project", $ns) -ne $null); 
			if ($valid) 
			{
				return [PSCustomObject]@{
					"Xmlns"=$ns;
					"Document"=$doc;
					"Path"=$path;
				};
			}
		}
		catch { return $false; } 
		
	}
	return $false;
}