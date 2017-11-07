function Out-NuGetTokens()
{
	<#
	.SYNOPSIS
	This function converts a [Acklann.Buildbox.Versioning.Manifest] object a list of token=value pairs, separated by semicolons.

	.DESCRIPTION
	This function will serialize a [Acklann.Buildbox.Versioning.Manifest] object to the following format "<nugetToken>=<value>;". The purpose of this is so the string can be consumed by the 'nuget pack' command, thus making the values of the [Acklann.Buildbox.Versioning.Manifest] accessible as [replacement tokens](https://docs.microsoft.com/en-us/nuget/schema/nuspec#replacement-tokens).

	.PARAMETER Manifest
	The [Acklann.Buildbox.Versioning.Manifest] object to convert.

	.PARAMETER BranchName
	The repo branch name. This value will be passed to the Manifest object's GetBranchSuffix(string: branchName) method to get a value for the version suffix.

	.INPUTS
	Acklann.Buildbox.Versioning.Manifest

	.OUTPUTS
	System.String

	.EXAMPLE
	&nuget pack .\package.nuspec -Properties $(Out-NuGetTokens $manifest);
	This example passes the [Acklann.Buildbox.Versioning.Manifest] Properties to be used as replacement tokens for 'nuget pack' command. 

	.EXAMPLE
	$props = Out-NuGetTokens $manifest -branch "master";
	This example converts [Acklann.Buildbox.Versioning.Manifest] to a string.

	.LINK
	https://docs.microsoft.com/en-us/nuget/schema/nuspec#replacement-tokens

	.LINK
	Get-BuildboxManifest
	#>
	
	Param(
		[Parameter(Mandatory, ValueFromPipeline)]
		$Manifest,

		[Alias('b', "branch")]
        [Parameter(Position = 1)]
		[string]$BranchName
	)

	$metadata = "";
	$metadata += "id=$($Manifest.PackageId);";
	$metadata += "title=$($Manifest.Title);";
	$metadata += "authors=$($Manifest.Authors);";
	$metadata += "tags=$($Manifest.Tags);";
	$metadata += "owners=$($Manifest.Owner);";
	$metadata += "iconUrl=$($Manifest.IconUri);";
	$metadata += "copyright=$($Manifest.Copyright);";
	$metadata += "projectUrl=$($Manifest.ProjectUrl);";
	$metadata += "licenseUrl=$($Manifest.LicenseUri);";
	$metadata += "description=$($Manifest.Description);";
	$metadata += "releaseNotes=$($Manifest.ReleaseNotes);";
	$metadata += "version=$($Manifest.Version.ToString());";

	$seperator = "";
	$versionSuffix = $Manifest.GetBranchSuffix($BranchName);
	if (-not [string]::IsNullOrEmpty($versionSuffix))
	{
		$seperator = "-";
	}

	$metadata += "suffix=$($seperator)$versionSuffix;";
	
	return $metadata;
}