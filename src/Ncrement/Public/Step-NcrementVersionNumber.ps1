<#
.SYNOPSIS
Increments the specified [Manifest] version number.

.PARAMETER Manifest
The [Manifest] object.

.PARAMETER Major
Determines whether the 'Major' version number should be incremented.

.PARAMETER Minor
Determines whether the 'Minor' version number should be incremented.

.PARAMETER Patch
Determines whether the 'Patch' version number should be incremented.

.PARAMETER Branch
The current source control branch. 

.INPUTS
[Manifest]

.OUTPUTS
[Version]

.EXAMPLE
$version = Get-NcrementManifest | Step-NcrementVersionNumber -Minor;

.EXAMPLE
$version = Get-NcrementManifest | Step-NcrementVersionNumber "master" -Patch;

.LINK
Get-NcrementManifest

.LINK
New-NcrementManifest

.LINK
Save-NcrementManifest
#>

function Step-NcrementVersionNumber
{
	Param(
		[Parameter(Mandatory, ValueFromPipeline)]
		$Manifest,

		[Parameter(Position = 0)]
		[string]$Branch,

		[Alias("break")]
		[switch]$Major,
		
		[Alias("feature")]
		[switch]$Minor,
		
		[Alias("fix", "bug")]
		[switch]$Patch
	)



	return $Manifest.Version;
}