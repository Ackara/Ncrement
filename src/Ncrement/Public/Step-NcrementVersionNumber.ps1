<#
.SYNOPSIS
Increments the specified [Manifest] version number.

.DESCRIPTION
This function increments the [Manifest] version number.

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
		[Parameter(Mandatory, ValueFromPipeline, Position = 1)]
		$Manifest,

		[Parameter(Position = 0)]
		[string]$Branch = "",

		[Alias("break")]
		[switch]$Major,

		[Alias("feature")]
		[switch]$Minor,

		[Alias("fix", "bug")]
		[switch]$Patch
	)

	# Incrementing the [Manifest] version number.
	$version = $Manifest.Version;
	if ($Major)
	{
		$version.Major += 1;
		$version.Minor = 0;
		$version.Patch = 0;
	}
	elseif ($Minor)
	{
		$version.Minor += 1;
		$version.Patch = 0;
	}
	elseif ($Patch)
	{
		$version.Patch += 1;
	}

	# Resolving the current branch name if it was not given.
	if ([string]::IsNullOrEmpty($Branch) -and (Test-GitRepository))
	{
		$context = (&git branch | Out-String);
		$regex = New-Object Regex -ArgumentList @('(?i)\*\s+(?<name>\w+)');
		$match = $regex.Match($context);

		if ($match.Success)
		{
			$Branch = $match.Groups["name"].Value;
		}
	}

	# Adding the 'Suffix' property to [Version] if it is missing.
	if ($version.PSObject.Properties.Match("Suffix").Count -eq 0)
	{
		$version | Add-Member -MemberType NoteProperty -Name "Suffix" -Value "";
	}

	# Getting the branch suffix.
	if ($Manifest.PSObject.Properties.Match("BranchSuffixMap").Count -gt 0)
	{
		$match = $Manifest.BranchSuffixMap.PSObject.Properties.Match($Branch);
		if ($match.Count -eq 1)
		{
			$version.Suffix = $match.Item(0).Value;
		}
		elseif ($Manifest.BranchSuffixMap.PSObject.Properties.Match("*").Count -gt 0)
		{
			$version.Suffix = $Manifest.BranchSuffixMap."*";
		}
	}
	else { Write-Warning "The 'BranchSuffixMap' property is undefined."; }

	# Saving the changes made to [Manifest].
	$Manifest | Save-NcrementManifest;

	return $Manifest.Version;
}