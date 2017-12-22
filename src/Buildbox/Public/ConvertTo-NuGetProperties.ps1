<#
.SYNOPSIS
This function converts a [Manifest] object a list of token=value pairs, separated by semicolons.

.DESCRIPTION
This function will serialize a [Manifest] object to the following format "<nugetToken>=<value>;". The purpose of this is so the string can be consumed by the 'nuget pack' command, thus making the values of the [Manifest] accessible as [replacement tokens](https://docs.microsoft.com/en-us/nuget/schema/nuspec#replacement-tokens).

.PARAMETER Manifest
The [Manifest] object to convert.

.PARAMETER BranchName
The repo branch name. This value will be passed to the Manifest object's GetVersionSuffix(string: branchName) method to get a value for the version suffix.

.INPUTS
Manifest

.OUTPUTS
System.String

.EXAMPLE
&nuget pack .\package.nuspec -Properties $(ConvertTo-NuGetProperties $manifest);
This example passes the [Manifest] Properties to be used as replacement tokens for 'nuget pack' command. 

.EXAMPLE
$props = ConvertTo-NuGetProperties $manifest -branch "master";
This example converts [Manifest] to a string.

.LINK
https://docs.microsoft.com/en-us/nuget/schema/nuspec#replacement-tokens

.LINK
Get-BuildboxManifest
#>
function ConvertTo-NuGetProperties()
{
	Param(
		[Parameter(Mandatory, ValueFromPipeline)]
		$Manifest,

		[Alias('b', "branch")]
        [Parameter(Position = 1)]
		[string]$BranchName
	)

	$metadata = "";
	$metadata += "tags=$($Manifest.Tags);";
	$metadata += "owners=$($Manifest.Owner);";
	$metadata += "authors=$($Manifest.Authors);";
	$metadata += "iconUrl=$($Manifest.IconUri);";
	$metadata += "title=$($Manifest.ProductName);";
	$metadata += "copyright=$($Manifest.Copyright);";
	$metadata += "projectUrl=$($Manifest.ProjectUrl);";
	$metadata += "licenseUrl=$($Manifest.LicenseUri);";
	$metadata += "description=$($Manifest.Description);";
	$metadata += "releaseNotes=$($Manifest.ReleaseNotes);";
	$metadata += "version=$($Manifest.Version.ToString());";

	$seperator = "";
	$versionSuffix = $Manifest.GetVersionSuffix($BranchName);
	if (-not [string]::IsNullOrEmpty($versionSuffix))
	{
		$seperator = "-";
	}

	$metadata += "suffix=$($seperator)$versionSuffix;";
	
	return $metadata;
}