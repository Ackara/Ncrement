function Edit-PackageJson
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
		$temp = Test-PackageJson $InputObject ;
		$path = $temp.Path;
		$package = $temp.Content;

		if ($package -ne $null)
		{
			[string]$name = $Manifest.Name;
			if (-not [string]::IsNullOrEmpty($null)) { $name = $name.ToLowerInvariant(); }

			$tags = @();
			if (-not [string]::IsNullOrEmpty($Manifest.Tags)) { $tags = $Manifest.Tags.Split(' '); }

			[bool]$appliedChanges = $false;
			$version = ConvertTo-NcrementVersionNumber $Manifest | Select-Object -ExpandProperty Version;

			foreach ($token in @{
				"name"=$name;
				"author"=$Manifest.Author;
				"homepage"=$Manifest.Website;
				"description"=$Manifest.Description;
				"keywords"=$tags;
				"repository"=$Manifest.Repository;
				"version"=$version;
			}.GetEnumerator())
			{
				if (($token.Value -ne $null) -and (-not [string]::IsNullOrWhiteSpace($token.Value)))
				{
					$appliedChanges = $true;
					if ($token.Name -eq "repository")
					{
						$token.Value = @{"type"="git"; "url"=$token.Value; }
					}

					if ($package | Get-Member $token.Name) { $package."$($token.Name)" = $token.Value; }
					else { $package | Add-Member -MemberType NoteProperty -Name $token.Name -Value $token.Value; }
				}
			}

			if ($appliedChanges -and $PSCmdlet.ShouldProcess($InputObject)) { $package | ConvertTo-Json | Out-File $path -Encoding utf8; }
			return $InputObject;
		}
	}
}