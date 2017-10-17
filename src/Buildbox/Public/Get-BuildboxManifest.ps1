function Get-BuildboxManifest()
{
	<#
	.SYNOPSIS
	This function creates a new [Acklann.Buildbox.Versioning.Manifest] instance from the specified path.

	.DESCRIPTION
	This function will create a new [Acklann.Buildbox.Versioning.Manifest] instance from the given path. If no path is given the funtion will search the current directory for a 'manifest.json' file; Passing a path to a directory will also invoke the same behavior.
	
	.PARAMETER Path
	The path of the manifest file.

	.INPUTS
	System.String

	.OUTPUTS
	Acklann.Buildbox.Versioning.Manifest

	.EXAMPLE
	Get-BuildboxManifest;
	This example creates a new [Acklann.Buildbox.Versioning.Manifest] from the 'manifest.json' file withing the current directory.

	Get-BuildboxManifest "C:\newproject\manifest.json";
	This example creates a new [Acklann.Buildbox.Versioning.Manifest] from the specified path.
	#>

	Param(
		[Alias('p')]
		[Parameter(ValueFromPipeline)]
		[string]$Path = "$PWD\manifest.json"
	)

	if (Test-Path $Path -PathType Leaf)
	{
		return [Acklann.Buildbox.Versioning.Manifest]::Load($Path);
	}
	elseif (Test-Path $Path -PathType Container)
	{
		return [Acklann.Buildbox.Versioning.Manifest]::Load("$Path\manifest.json");
	}
	else
	{
		throw "Cannot find file at '$Path'.";
	}
}