function Edit-NetFrameworkProjectFile
{
	[CmdletBinding(SupportsShouldProcess)]
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
		$proj = Test-NetFrameworkProjectFile $InputObject;
		if ($proj)
		{
			$path = $proj.Path;
			$hasChanges = $false;
			$version = ConvertTo-NcrementVersionNumber $Manifest | Select-Object -ExpandProperty Version;
			$infoFile = Join-Path (Split-Path $path -Parent) "Properties/AssemblyInfo.cs";
			$contents = Get-Content $infoFile | Out-String;

			if ((Test-Path $infoFile))
			{
				foreach ($token in @{
					"AssemblyTitle"=$Manifest.Name;
					"AssemblyProduct"=$Manifest.Name;
					"AssemblyCompany"=$Manifest.Company;
					"AssemblyDescription"=$Manifest.Description;
					"AssemblyCopyright"=$Manifest.Copyright;
					"AssemblyInformationalVersion"=$version;
					"AssemblyFileVersion"=$version;
					"AssemblyVersion"=$version;
				}.GetEnumerator())
				{
					if (($token.Value -ne $null) -and (-not [string]::IsNullOrWhiteSpace($token.Value)))
					{
						$hasChanges = $true;
						$pattern = [string]::Format('(?i){0}\s*\(\s*(?<value>"?.*"?)\)', $token.Name);
						$match = [Regex]::Match($contents, $pattern);

						if ($match.Success)
						{
							$contents = [Regex]::Replace($contents, $pattern, "$($token.Name)(`"$($token.Value)`")");
						}
						else
						{
							$contents = [string]::Concat($contents.TrimEnd(), [Environment]::NewLine, "[assembly: $($token.Name)(`"$($token.Value)`")");
						}
					}
				}
				if ($PSCmdlet.ShouldProcess($infoFile)) { $contents | Out-File $infoFile -Encoding utf8; }
				return $infoFile;
			}
		}

		return $false;
	}
}