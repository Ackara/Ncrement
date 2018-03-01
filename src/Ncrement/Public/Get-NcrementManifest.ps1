<#
.SYNOPSIS
Creates a new [Manifest] instance from the specified path.

.DESCRIPTION
This function creates a new [Manifest] instance from the specified path. If a path is not provided the function will search the current directory for a 'manifest.json' file; passing a path to a directory will also invoke the same behavior.

.PARAMETER Path
The path of the manifest file.

.PARAMETER CreateIfNotFound
Determines wether to create a new 'manifest.json' file if none exist at the specified path.

.INPUTS
[String]

.OUTPUTS
[Manifest]

.EXAMPLE
Get-NcrementManifest;
This example creates a new [Manifest] from the 'manifest.json' file withing the current directory.

Get-NcrementManifest "C:\newproject\manifest.json";
This example creates a new [Manifest] from the specified path.

.LINK
New-NcrementManifest

.LINK
Save-NcrementManifest
#>

function Get-NcrementManifest
{
	Param(
		[Alias('p', 'file')]
		[Parameter(ValueFromPipeline)]
		[string]$Path,

		[Alias('c', "save", "create", "force")]
		[switch]$CreateIfNotFound
	)

	# Resolving the specified manifest path.
	if ([string]::IsNullOrEmpty($Path))
		{ $Path = "$PWD\manifest.json"; }
	elseif ((Test-Path $Path -PathType Container))
		{ $Path = Join-Path $Path "manifest.json"; }

	if ((-not (Test-Path $Path -PathType Leaf)) -and $CreateIfNotFound.IsPresent)
	{
		$manifest = New-NcrementManifest;
		$manifest | Save-NcrementManifest $Path;
		return $manifest;
	}
	elseif (-not (Test-Path $Path -PathType Leaf))
	{
		throw "Could not file file at '$Path'.";
	}

	# Extracting the manifest object from .json file.
	$json = Get-Content $Path | Out-String | ConvertFrom-Json;
	$manifest = $json.PSObject.Properties | Where-Object { ($_.Name -ieq "manifest") -or ($_.Name -ieq "project") -or ($_.Name -ieq "product")  } | Select-Object -ExpandProperty Value -First 1;
	if ($manifest -eq $null) { $manifest = $json; }

	# Appending missing properties.
	if ($manifest.PSObject.Properties.Match("Path").Count -eq 0)
	{
		$manifest | Add-Member -MemberType NoteProperty -Name "Path" -Value $Path;
	}

	$model = New-NcrementManifest;
	foreach ($prop in $model.PSObject.Properties)
	{
		if ($manifest.PSObject.Properties.Match($prop.Name).Count -eq 0)
		{
			$manifest | Add-Member -MemberType NoteProperty -Name $prop.Name -Value "";
		}
	}

	return $manifest;
}