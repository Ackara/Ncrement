function Test-VSIXManifest{
	Param(
		[Parameter(ValueFromPipeline)]
		$InputObject
	)

	$path = ConvertTo-Path $InputObject;
	if ($path -and ($path.EndsWith(".vsixmanifest")))
	{
		[xml]$doc = $null;
		try { $doc = Get-Content $path; } catch { return $false; }
		$ns = [System.Xml.XmlNamespaceManager]::new($doc.NameTable);
		$ns.AddNamespace("x", "http://schemas.microsoft.com/developer/vsx-schema/2011");

		try
		{
			$matchFound = ($doc.SelectSingleNode("//x:Metadata", $ns) -ne $null);
			if ($matchFound)
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