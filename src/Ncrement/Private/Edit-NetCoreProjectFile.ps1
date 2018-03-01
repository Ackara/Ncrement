<#
.SYNOPSIS
Updates all 'netcore' projects in a directory using the in the specified [Manifest] object.

.PARAMETER $Manifest
The [Manifest] object.

.PARAMETER Path
The project directory.
#>

function Edit-NetCoreProjectFile
{
	Param(
		[Parameter(Mandatory, ValueFromPipeline)]
		$Manifest,

		[string]$Path
	)

	$modifiedFiles = [System.Collections.ArrayList]::new();
	if (Test-Path $Path -PathType Container)
	{
		foreach ($csproj in (Get-ChildItem $Path -Filter "*.csproj" -Recurse))
		{
			[xml]$doc = Get-Content $csproj.FullName;
			$netcoreProject = &{ try { return ($doc.SelectSingleNode("//Project[@Sdk]") -ne $null); } catch { return $false; } };

			if ($netcoreProject -and ($PSCmdlet.ShouldProcess($csproj)))
			{
				$version = $Manifest | Convert-NcrementVersionNumberToString;
				$propertyGroup = $doc.SelectSingleNode("/Project/PropertyGroup[1]");
				foreach ($token in @(
					[Ncrement.Token]::new("Title", $manifest.Name),
					[Ncrement.Token]::new("AssemblyVersion", $version),
					[Ncrement.Token]::new("PackageVersion", $version),
					[Ncrement.Token]::new("Description", $manifest.Description),
					[Ncrement.Token]::new("Authors", $manifest.Author),
					[Ncrement.Token]::new("Company", $manifest.Company),
					[Ncrement.Token]::new("PackageTags", $manifest.Tags),
					[Ncrement.Token]::new("Copyright", $manifest.Copyright),
					[Ncrement.Token]::new("PackageIconUrl", $manifest.Icon),
					[Ncrement.Token]::new("PackageProjectUrl", $manifest.Website),
					[Ncrement.Token]::new("PackageLicenseUrl", $manifest.License),
					[Ncrement.Token]::new("PackageReleaseNotes", $manifest.ReleaseNotes),
					[Ncrement.Token]::new("RepositoryUrl", $manifest.RepositoryUrl)
				))
				{
					if (-not [string]::IsNullOrEmpty($token.Value))
					{
						$element = $doc.SelectSingleNode("//PropertyGroup/$($token.TagName)");
						if ($element -eq $null)
						{
							$node = $doc.CreateElement($token.TagName);
							$data = &{ if ($token.Value -match '(\n|[><])') { return $doc.CreateCDataSection($token.Value); } else { return $doc.CreateTextNode($token.Value); }};
							$node.AppendChild($data) | Out-Null;
							$propertyGroup.AppendChild($node) | Out-Null;
						}
						else
						{
							$element.InnerText = $token.Value;
						}
					}
				}
				$doc.Save($csproj.FullName);
			}

			if ($netcoreProject) { $modifiedFiles.Add($csproj.FullName) | Out-Null; }
		}
	}

	return $modifiedFiles;
}