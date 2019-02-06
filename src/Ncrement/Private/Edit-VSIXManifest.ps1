function Edit-VSIXManifest
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
		$path = ConvertTo-Path $Manifest;
		if ((-not [string]::IsNullOrEmpty($path)) -and (Test-Path $path -PathType Leaf)) { $Manifest = Get-Content $path | ConvertFrom-Json; }
	}

	PROCESS
	{
		$vsix = Test-VSIXManifest $InputObject;
		if ($vsix)
		{
			$madeChanged = $false;
			$ns = $vsix.Xmlns;
			$metadata = $vsix.Document.SelectSingleNode("//x:Metadata", $ns);

			if ($metadata -ne $null)
			{
				$version = ConvertTo-NcrementVersionNumber $Manifest;
				$identity = $metadata.SelectSingleNode("x:Identity", $ns);

				foreach ($token in @{
					"Version"=$version;
				}.GetEnumerator())
				{
					if (($token.Value -ne $null) -and (-not [string]::IsNullOrWhiteSpace($token.Value)))
					{
						$madeChanged = $true;
						$attr = $identity.Attributes[$token.Name];
						if ($attr -eq $null)
						{
							$attr = $vsix.Document.CreateAttribute($token.Name);
							$attr.Value = $token.Value;
							$identity.Attributes.Append($attr) | Out-Null;
						}
						else { $attr.Value = $token.Value; }
					}
				}

				foreach ($token in @{
					"DisplayName"=$Manifest.Name;
					"Description"=$Manifest.Description;
					"Tags"=$Manifest.Tags;
				}.GetEnumerator())
				{
					if (($token.Value -ne $null) -and (-not [string]::IsNullOrWhiteSpace($token.Value)))
					{
						$data = $null;
						if ($token.Value -match '[\n><]') { $data = $vsix.Document.CreateCDataSection($token.Value); }
						else { $data = $vsix.Document.CreateTextNode($token.Value); }

						$madeChanged = $true;
						$node  = $metadata.SelectSingleNode("x:$($token.Name)", $ns);

						if ($node -eq $null)
						{
							$item = $vsix.Document.CreateElement($token.Name, "http://schemas.microsoft.com/developer/vsx-schema/2011");
							$item.AppendChild($data) | Out-Null;
							$metadata.AppendChild($item) | Out-Null;
						}
						else
						{
							$node.RemoveAll() | Out-Null;
							$node.AppendChild($data) | Out-Null;
						}
					}
				}

				if ($PSCmdlet.ShouldProcess($InputObject)) { $vsix.Document.Save($vsix.Path); }
				return $InputObject;
			}
		}
	}
}