function Edit-NetcoreProjectFile
{
	[CmdletBinding(ConfirmImpact = "Medium", SupportsShouldProcess)]
	Param(
		[Parameter(Mandatory)]
		$Manifest,

		[Parameter(Mandatory, ValueFromPipeline)]
		$InputObject
	)

	BEGIN
	{
		[string]$path = ConvertTo-Path $Manifest;
		if ((-not [string]::IsNullOrEmpty($path)) -and (Test-Path $path -PathType Leaf)) { $Manifest = Get-Content $path | ConvertFrom-Json; }
	}

	PROCESS
	{
		$path = ConvertTo-Path $InputObject;
		$doc = Test-NetcoreProjectFile $InputObject;
		if ($doc)
		{
			$hasChanges = $false;
			$hasNewNodes = $false;
			$myGroup = $doc.CreateElement("PropertyGroup");
			$version = ConvertTo-NcrementVersionNumber $Manifest;

			foreach ($token in @{
				"Title"=$Manifest.Name;
				"PackageVersion"=$version;
				"AssemblyVersion"=$version;
				"Description"=$Manifest.Description;
				"Authors"=$Manifest.Author;
				"Company"=$Manifest.Company;
				"Copyright"=$Manifest.Copyright;
				"PackageTags"=$Manifest.Tags;

				"PackageProjectUrl"=$Manifest.Website;
				"PackageIconUrl"=$Manifest.Icon;
				"PackageReleaseNotes"=$Manifest.ReleaseNotes;
				"RepositoryUrl"=$Manifest.RepositoryUrl;
				"PackageLicenseUrl"=$Manifest.License;
			}.GetEnumerator())
			{
				if (($token.Value -ne $null) -and (-not [string]::IsNullOrWhiteSpace($token.Value)))
				{
					$hasChanges = $true;
					$element = $doc.SelectSingleNode("//PropertyGroup/$($token.Name)");

					$data = $null;
					if ($token -match '(\n|[><])') { $data = $doc.CreateCDataSection($token.Value) }
					else { $data = $doc.CreateTextNode($token.Value); }

					if ($element -eq $null)
					{
						$hasNewNodes = $true;
						$node = $doc.CreateElement($token.Name);
						$node.AppendChild($data) | Out-Null;
						$myGroup.AppendChild($node) | Out-Null;
					}
					else
					{
						$element.RemoveAll() | Out-Null;
						$element.AppendChild($data) | Out-Null;
					}
				}
			}

			if ($hasNewNodes)
			{
				$target = $doc.SelectSingleNode("/Project/PropertyGroup[1]");
				$doc.DocumentElement.InsertAfter($myGroup, $target) | Out-Null;
			}

			if ($PSCmdlet.ShouldProcess($InputObject)) { $doc.Save($path); }
			return $InputObject;
		}
		else { return $false; }
	}
}