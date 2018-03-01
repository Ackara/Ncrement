<#
.SYNOPSIS
Serializes the [Manifest] object to a file, overwriting an existing file, if it exists.

.DESCRIPTION
This function serializes a [Manifest] object to the given path. If no path is specified the funtion will save the object as 'manifest.json' in the current directory; Passing a path to a directory will also invoke the same behavior.

.PARAMETER Manifest
The [Manifest] object.

.PARAMETER Path
The file path.

.INPUTS
[Manifest]

.EXAMPLE
$savedPath = New-NcrementManifest | Save-NcrementManifest;
This example serializes the [Manifest] object at the current location.

.EXAMPLE
$savedPath = Save-NcrementManifest "C:\projects\myapp\manifest.json $manifest;
This example serializes the [Manifest] object at the specified location.

.LINK
New-NcrementManifest

.LINK
Get-NcrementManifest
#>

function Save-NcrementManifest
{
	Param(
		[Parameter(Mandatory, ValueFromPipeline, Position = 1)]
		$Manifest,

		[Alias('p', "file")]
		[Parameter(Position = 0)]
		[string]$Path
	)

	$clone = $Manifest | ConvertTo-Json | ConvertFrom-Json;

	# Resolving the manifest path
	if ([string]::IsNullOrEmpty($Path))
	{
		if (($clone.PSObject.Properties.Match("Path").Count -eq 1) -and (-not [string]::IsNullOrEmpty($clone.Path)))
		{
			$Path = $clone.Path;
		}
		else
		{
			$Path = "$PWD\manifest.json";
		}
	}
	elseif (Test-Path $Path -PathType Container)
	{ $Path = Join-Path $Path "manifest.json"; }
	elseif (-not [IO.Path]::IsPathRooted($Path))
	{ $Path = "$PWD\$Path"; }

	# Removing all null and unwanted values.
	$clone.PSObject.Properties.Remove("Path");
	foreach ($prop in $clone.PSObject.Properties)
	{
		if ($prop.Value -eq $null)
		{
			$clone.PSObject.Properties.Remove($prop.Name);
			Write-Host "Removing: $($prop.Name)";
		}
	}

	# Serializing [Manifest] object.
	if (Test-Path $Path)
	{
        [bool]$nested = $false;
		$json = Get-Content $Path | Out-String | ConvertFrom-Json;
		foreach ($term in @("manifest", "project", "product"))
		{
			if ($json.PSObject.Properties.Match($term).Count -gt 0)
			{
				$json.$term = $clone;
                $nested = $true;
				break;
			}
		}

        if ($nested) { $json | ConvertTo-Json | Out-File $Path -Encoding utf8; }
        else { $clone | ConvertTo-Json | Out-File $Path -Encoding utf8; }
	}
	else { $clone | ConvertTo-Json | Out-File $Path -Encoding utf8; }

	return $Path;
}