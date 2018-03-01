<#
.SYNOPSIS
Returns the string representation of a [Manifest] version object.

.PARAMETER InputObject
The [Manifest] object or [Version] object.

.PARAMETER Branch
The current branch name from source control.

.PARAMETER AppendSuffix
Determine wether to append the version suffix.

.INPUTS
[Manifest]
[Version]

.OUTPUTS
[String]

.EXAMPLE
$manifest | Convert-NcrementVersionNumberToString;
This example returns the [Manifest] version number as a string. eg: Major.Minor.Path-Suffix
#>

function Convert-NcrementVersionNumberToString
{
	Param(
		[Parameter(Mandatory, ValueFromPipeline)]
		$InputObject,

		[Parameter(Position=0)]
		[string]$Branch = "",

		[Alias("suffix")]
		[switch]$AppendSuffix
	)

	[string]$version = "", $suffix;
	if ($InputObject.PSObject.Properties.Match("Version").Count -gt 0)
	{
		if (-not [string]::IsNullOrEmpty($Branch))
		{
			$match = $InputObject.BranchSuffixMap.PSObject.Properties.Match($Branch);
			if ($match.Count -gt 0)
			{
				$suffix = $match.Item(0).Value;
			}
			elseif ($InputObject.BranchSuffixMap.PSObject.Properties.Match("*").Count -gt 0)
			{
				$suffix = $InputObject.BranchSuffixMap."*";
			}
		}
		else { $suffix = $InputObject.Version.Suffix; }
		$version = "$($InputObject.Version.Major).$($InputObject.Version.Minor).$($InputObject.Version.Patch)";
	}
	else
	{
		$suffix = $InputObject.Suffix;
		$version = "$($InputObject.Major).$($InputObject.Minor).$($InputObject.Patch)";
	}

	if ($AppendSuffix.IsPresent -and (-not [string]::IsNullOrEmpty($suffix)))
	{
		$version += "-$suffix";
	}

	return $version;
}

