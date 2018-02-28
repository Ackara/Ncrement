<#
.SYNOPSIS
Returns the string representation of a [Manifest] version object.

.PARAMETER InputObject
The [Manifest] object or [Version] object.

.PARAMETER AppendSuffix
Determine wether to append the version suffix.

.INPUTS
[Manifest]
[Version]

.OUTPUTS
[String]

.EXAMPLE
$manifest | Convert-NcrementVersionNumberToString;
This example returns the [Manifest] version number as a string.
#>

function Convert-NcrementVersionNumberToString
{
	Param(
		[Parameter(Mandatory, ValueFromPipeline)]
		$InputObject,

		[switch]$AppendSuffix
	)

	[string]$version = "";
	if ($InputObject.PSObject.Properties.Match("Version").Count -gt 0)
	{
		$version = "$($InputObject.Version.Major).$($InputObject.Version.Minor).$($InputObject.Version.Patch)";
		if ($AppendSuffix -and (-not [string]::IsNullOrEmpty($InputObject.Version.Suffix)))
		{
			$version = "$($version)-$($InputObject.Version.Suffix)";
		}
	}
	else
	{
		$version = "$($InputObject.Major).$($InputObject.Minor).$($InputObject.Patch)";
		if ($AppendSuffix -and (-not [string]::IsNullOrEmpty($InputObject.Suffix)))
		{
			$version = "$($version)-$($InputObject.Suffix)";
		}
	}

	return $version;
}

