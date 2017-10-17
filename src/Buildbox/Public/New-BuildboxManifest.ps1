function New-BuildboxManifest()
{
	<#
	.SYNOPSIS
	This function creates a new manifest file.

	.DESCRIPTION
	This function will create a new manifest file at the specified location and returns a [Acklann.Buildbox.SemVer.Manifest] object. If a -Path is not provided it will default to the current directory. Use the -Force switch to override an existing file.

	.PARAMETER Path
	The path of the manifest file.

	.PARAMETER Force
	Determines whether an existing file should be overriden.

	.INPUTS
	System.String

	.OUTPUTS
	Acklann.Buildbox.SemVer.Manifest

	.EXAMPLE
	New-BuildboxManifest;
	This example creates a new 'manifest.json' file in the current directory.
	
	.EXAMPLE
	New-BuildboxManifest "C:\new_project\manifest.json";
	This example creates a new 'manifest.json' file at the specified path.
	#>

	Param(
		[Alias('p')]
		[Parameter(ValueFromPipeline)]
		[string]$Path = "$PWD\manifest.json",

		[Alias('f')]
		[switch]$Force
	)
    
	if (Test-Path $Path -PathType Container)
	{
		$Path = "$Path\manifest.json";
	}

	if ((Test-Path $Path -PathType Leaf) -and (-not $Force.IsPresent))
	{
		throw "Cannot create '$Path' because it already exists. Use the -Force switch to overwrite the existing file.";
	}

	$manifest = New-Object Acklann.Buildbox.SemVer.Manifest($Path);
	$manifest.Save();
	return $manifest;
}
