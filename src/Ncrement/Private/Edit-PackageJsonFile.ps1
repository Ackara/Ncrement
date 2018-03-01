<#
.SYNOPSIS
Updates a 'package.json' files in a directory using the in the specified [Manifest] object.

.PARAMETER $Manifest
The [Manifest] object.

.PARAMETER Path
The project directory.
#>

function Edit-PackageJsonFile
{
	Param(
		[Parameter(Mandatory, ValueFromPipeline)]
		$Manifest,

		[string]$Path
	)

	$modifiedFiles = [System.Collections.ArrayList]::new();
	foreach ($file in (Get-ChildItem $Path -Recurse -Filter "package.json" | Select-Object -ExpandProperty FullName))
	{
		if ($PSCmdlet.ShouldProcess($file))
		{
			$package = Get-Content $file | Out-String | ConvertFrom-Json;
			foreach ($field in @{
				"name"=$Manifest.Name;
				"author"=$Manifest.Author;
				"homepage"=$Manifest.Website;
				"description"=$Manifest.Description;
				"keywords"=$Manifest.Tags.Split(' ');
				"repository"=$Manifest.RepositoryUrl;
				"version"=($Manifest | Convert-NcrementVersionNumberToString);
			}.GetEnumerator())
			{
				if (-not [string]::IsNullOrEmpty($field.Value))
				{
					if ($package.PSObject.Properties.Match($field.Name).Count -eq 0)
					{
						if ($field.Name -eq "repository")
						{
							$field.Value = @{"type"="git";"url"=$field.Value;};
						}

						$package | Add-Member -MemberType NoteProperty -Name $field.Name -Value $field.Value;
					}
					elseif ($field.Name -eq "repository")
					{
						$package.repository.url = $field.Value;
					}
					else
					{
						$package."$($field.Name)" = $field.Value;
					}
				}
			}

			$package | ConvertTo-Json | Out-File $file -Encoding utf8;
			$modifiedFiles.Add($file) | Out-Null;
		}
	}

	return $modifiedFiles;
}