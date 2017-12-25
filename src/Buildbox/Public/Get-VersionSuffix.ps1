<#
.SYNOPSIS
This function gets the current branch version suffix.

.DESCRIPTION
This function will return the appropriate version suffix based on source control (Git) current branch. It utilizes the BranchSuffixMap property on the specified [Manifest] object to determine the correct value.

.PARAMETER Manifest
The [Manifest] object.

.PARAMETER BranchName
The source control (Git) branch name.

.INPUTS
Manifest

OUTPUTS
System.String

.EXAMPLE
$versionSuffix = Get-BuildboxManifest | Get-VersionSuffix "master";

.LINK
Get-BuildboxManifest
#>
function Get-VersionSuffix()
{
	Param(
		[Alias('m')]
		[Parameter(Mandatory, ValueFromPipeline, Position = 2)]
		$Manifest,

		[Alias('b', "branch")]
		[Parameter(Position = 1)]
		[string]$BranchName
	)

	if ([string]::IsNullOrEmpty($BranchName) -and (Assert-GitIsInstalled))
	{
		$match = [Regex]::Match((& git branch), '\*\s*(?<name>\w+)');
		if ($match.Success) { $BranchName = $match.Groups["name"].Value; }
	}

	$suffix = $Manifest.GetVersionSuffix($BranchName);
	if ([string]::IsNullOrEmpty($suffix))
	{
		return "";
	}
	else
	{
		return $suffix;
	}
}