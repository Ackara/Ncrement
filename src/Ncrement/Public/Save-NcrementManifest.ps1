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

	# Resolving the manifest path
	if ([string]::IsNullOrEmpty($Path))
	{ $Path = "$PWD\manifest.json"; }
	elseif (Test-Path $Path -PathType Container)
	{ $Path = Join-Path $Path "manifest.json"; }
	elseif (-not [IO.Path]::IsPathRooted($Path))
	{ $Path = "$PWD\$Path"; }

	# Serializing [Manifest] object.
	$Manifest.PSObject.Properties.Remove("Path");

	if (Test-Path $Path)
	{
		$json = Get-Content $Path | Out-String | ConvertFrom-Json;
		$prop = $json.PSObject.Properties | Where-Object { $_.Name -ieq "manifest" } | Select-Object -First 1;
		if (-not ($prop -eq $null))
		{
			$json.Manifest = $Manifest;
		}
		$json | ConvertTo-Json | Out-File $Path -Encoding utf8;
	}
	else
	{
		$Manifest | ConvertTo-Json | Out-File $Path -Encoding utf8;
	}

	return $Path;
}