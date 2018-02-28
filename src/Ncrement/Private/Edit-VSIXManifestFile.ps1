<#
.SYNOPSIS
Updates a 'netcore' all projects in a directory using the in the specified [Manifest] object.

.PARAMETER $Manifest
The [Manifest] object.

.PARAMETER Path
The project directory.
#>

function Edit-VSIXManifestFile
{
	Param(
		[Parameter(Mandatory, ValueFromPipeline)]
		$Manifest,

		[string]$Path
	)

	$modifiedFiles = [System.Collections.ArrayList]::new();
	foreach ($vsixmanifest in (Get-ChildItem $Path -Recurse -Filter "*.vsixmanifest"))
	{
		if ($PSCmdlet.ShouldProcess($vsixmanifest.FullName))
		{
			[xml]$doc = Get-Content $vsixmanifest.FullName;
			$ns = New-Object Xml.XmlNamespaceManager $doc.NameTable;
			$ns.AddNamespace("x", "http://schemas.microsoft.com/developer/vsx-schema/2011");

			$metadata = $doc.SelectSingleNode("//x:Metadata", $ns);

			if ($metadata -ne $null)
			{
				$version = $Manifest | Convert-NcrementVersionNumberToString;
				$identity = $metadata.SelectSingleNode("x:Identity", $ns);
				foreach ($token in @(
					[Ncrement.Token]::new("Version", $version),
					[Ncrement.Token]::new("Publisher", $manifest.Owner)
				))
				{
					if (-not [string]::IsNullOrEmpty($token.Value))
					{
						$attribute = $identity.Attributes[$token.TagName];
						if ($attribute -eq $null)
						{
							$attr = $doc.CreateAttribute($token.TagName);
							$attr.Value = $token.Value;
					        $identity.Attributes.Append($attr) | Out-Null;
						}
						else
						{
							$attribute.Value = $token.Value;
						}
					}
				}

				foreach ($token in @(
					[Ncrement.Token]::new("DisplayName", $manifest.Name),
					[Ncrement.Token]::new("Description", $manifest.Description),
					[Ncrement.Token]::new("Tags", $manifest.Tags)
				))
				{
					if (-not [string]::IsNullOrEmpty($token.Value))
					{
						$node = $metadata.SelectSingleNode("x:$($token.TagName)", $ns);
						if ($node -eq $null)
						{
							$n = $doc.CreateElement($token.TagName, "http://schemas.microsoft.com/developer/vsx-schema/2011");
							$data = &{ if ($token.Value -match '[\n><]') { return $doc.CreateCDataSection($token.Value); } else { return $doc.CreateTextNode($token.Value); } };
							$n.AppendChild($data) | Out-Null;
							$metadata.AppendChild($n) | Out-Null;
						}
						else
						{
							$node.InnerText = $token.Value;
						}
					}
				}
				$doc.Save($vsixmanifest.FullName) | Out-Null;
			}
		}

		$modifiedFiles.Add($vsixmanifest.FullName) | Out-Null;
	}

	return $modifiedFiles;
}