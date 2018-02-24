<#
.SYNOPSIS
This function gets the current branch version number.

.DESCRIPTION
This function will return the appropriate version number based on source control (Git) current branch. It utilizes the BranchSuffixMap property on the specified [Manifest] object to determine the correct value.

.PARAMETER Manifest
The [Manifest] object.

.PARAMETER BranchName
The source control (Git) branch name.

.PARAMETER NumberOnly
Determines whether to ommit the version suffix.

.PARAMETER SuffixOnly
Determines whether to return the version suffix only.

.INPUTS
Manifest

OUTPUTS
System.String

.EXAMPLE
$version = Get-BuildboxManifest | Get-VersionNumber "master";
This example gets the full version number for the master branch.

.EXAMPLE
$versionSuffix = Get-BuildboxManifest | Get-VersionNumber "master" -SuffixOnly;
This example gets the version suffix for the master branch.

.LINK
Get-BuildboxManifest
#>
function Get-VersionNumber()
{
	Param(
		[Alias('m')]
		[Parameter(Mandatory, ValueFromPipeline, Position = 2)]
		$Manifest,

		[Alias('b', "branch")]
		[Parameter(Position = 1)]
		[string]$BranchName,

		[Alias('s', "suffix")]
		[switch]$SuffixOnly,

		[Alias('n', "number")]
		[switch]$NumberOnly
	)

	if ([string]::IsNullOrEmpty($BranchName) -and (Assert-GitIsInstalled))
	{
		$match = [Regex]::Match((& git branch), '\*\s*(?<name>\w+)');
		if ($match.Success) { $BranchName = $match.Groups["name"].Value; }
	}
	$suffix = $Manifest.GetVersionSuffix($BranchName);
	$version = $Manifest.Version.ToString();

	if ($NumberOnly)
	{
		return $version;
	}
	elseif ($SuffixOnly)
	{
		return $suffix;
	}
	else
	{
		return ([string]::IsNullOrEmpty($suffix)) | Coalesce $version "$version-$suffix";
	}
}