<#
.SYNOPSIS
Updates a 'net-framework' all projects in a directory using the in the specified [Manifest] object.

.PARAMETER $Manifest
The [Manifest] object.

.PARAMETER Path
The project directory.
#>

function Edit-NetFrameworkProjectFile
{
	Param(
		[Parameter(Mandatory, ValueFromPipeline)]
		$Manifest,

		[string]$Path
	)

	$modifiedFiles = [System.Collections.ArrayList]::new();

	foreach ($csproj in (Get-ChildItem $Path -Recurse -Filter "*.csproj"))
	{
		[string]$assemblyInfo = "$(Split-Path $csproj.FullName -Parent)\Properties\AssemblyInfo.cs";
		if ((Test-Path $assemblyInfo) -and ($PSCmdlet.ShouldProcess($assemblyInfo)))
		{
			$version = $Manifest | Convert-NcrementVersionNumberToString;
			$contents = Get-Content $assemblyInfo | Out-String;
			foreach ($token in @(
				[Ncrement.Token]::new("Title", "`"$($manifest.Name)`""),
				[Ncrement.Token]::new("Product", "`"$($manifest.Name)`""),
				[Ncrement.Token]::new("Company", "`"$($manifest.Company)`""),
				[Ncrement.Token]::new("Description", "`"$($manifest.Description)`""),
				[Ncrement.Token]::new("Copyright", "`"$($manifest.Copyright)`""),
				[Ncrement.Token]::new("InformationalVersion", "`"$($version)`""),
				[Ncrement.Token]::new("FileVersion", "`"$($version)`""),
				[Ncrement.Token]::new("Version", "`"$($version)`"")
			))
			{
				if (-not [string]::IsNullOrEmpty($token.Value))
				{
					$matches = [Regex]::Matches($contents, [string]::Format('(?i)Assembly{0}\s*\(\s*(?<value>"?.*"?)\)', $token.TagName));
					if ($matches.Count -ge 1)
					{
						foreach ($match in $matches)
						{
							$value = $match.Groups["value"];
							$contents = $contents.Remove($value.Index, $value.Length);
							$contents = $contents.Insert($value.Index, $token.Value);
						}
					}
					else
					{
						$contents = [string]::Concat($contents.TrimEnd(), [System.Environment]::NewLine, "[assembly: Assembly$($token.TagName)($($token.Value))]");
					}
				}
			}
			$contents | Out-File $assemblyInfo -Encoding utf8;
		}

		if (Test-Path $assemblyInfo) { $modifiedFiles.Add($assemblyInfo) | Out-Null; }
	}

	return $modifiedFiles;
}