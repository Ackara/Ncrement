<#
.SYNOPSIS
Increments the specified [Manifest] version number using the [DateTime]::UtcNow.

.DESCRIPTION
This function increments the [Manifest] version number using the [DateTime]::UtcNow object. If values passed to the 'Major', 'Minor' and 'Patch' parameters are not intergers, the their values will be used as format strings for the [DateTime]::ToString method. Also when invoked, the version will be incremented then the modified [Manifest] object will be saved to disk as well.

.PARAMETER Manifest
The [Manifest] object.

.PARAMETER Major
The major version number. Accpets  Defaults to 'yyMM'.

.PARAMETER Minor
The minor version number. Defaults to 'ddHH'.

.PARAMETER Patch
The patch version number. Defaults to 'Path + 1'.

.PARAMETER Branch
The source control branch. The value provided will be used to determine the version suffix. If not set 'git branch' will be used as default.

.PARAMETER DoNotSave
Determines whether to not save the modified [Manifest] object to disk.

.INPUTS
[Manifest]

.OUTPUTS
[Manifest]

.EXAMPLE
$version = Get-NcrementManifest | Step-NcrementVersionNumberUsingDate -Major "yyMM" -Minor "ddmm";
In this example, because DateTime format strings were passed, each value will be used as the argument for the [DateTime]::UtcNow.ToString() method to replace their respective values.

.EXAMPLE
$version = Get-NcrementManifest | Step-NcrementVersionNumberUsingDate -Major "1709" -Minor "1123" -Patch "4586";
In this example, because integers were passed the function will return "1709.1123.4586".

.LINK
Get-NcrementManifest

.LINK
New-NcrementManifest

.LINK
Save-NcrementManifest
#>

function Step-NcrementVersionNumberUsingDate
{
	Param(
		[Parameter(Mandatory, ValueFromPipeline, Position=4)]
		$Manifest,

		[Alias("break")]
		[Parameter(Position=0)]
		[string]$Major = "yyMM",

		[Alias("feature")]
		[Parameter(Position=1)]
		[string]$Minor = "ddHH",

		[Alias("fix", "bug")]
		[Parameter(Position=2)]
		[string]$Patch = "",

		[Alias('b')]
		[Parameter(Position=3)]
		[string]$Branch,

		[switch]$DoNotSave
	)

	# Incrementing the version number.
	$Manifest.Version.Major = ConvertTo-Version $Major $Manifest.Version.Major;
	$Manifest.Version.Minor = ConvertTo-Version $Minor $Manifest.Version.Minor;
	$Manifest.Version.Patch = ConvertTo-Version $Patch ($Manifest.Version.Patch + 1);

	# Resolving the current branch name if it was not given.
	try
	{
		[string]$repo = "";
		if ([string]::IsNullOrEmpty($Manifest.Path)) { $repo = $PWD; }
		else { $repo = Split-Path $Manifest.Path -Parent; }
		
		Push-Location $repo;
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
	}
	finally { Pop-Location; }

	# Adding the 'Suffix' property to [Version] if it is missing.
	if ($Manifest.Version.PSObject.Properties.Match("Suffix").Count -eq 0)
	{
		$Manifest.Version | Add-Member -MemberType NoteProperty -Name "Suffix" -Value "";
	}

	# Getting the branch suffix.
	if ($Manifest.PSObject.Properties.Match("BranchSuffixMap").Count -gt 0)
	{
		$match = $Manifest.BranchSuffixMap.PSObject.Properties.Match($Branch);
		if ($match.Count -eq 1)
		{
			$Manifest.Version.Suffix = $match.Item(0).Value;
		}
		elseif ($Manifest.BranchSuffixMap.PSObject.Properties.Match("*").Count -gt 0)
		{
			$Manifest.Version.Suffix = $Manifest.BranchSuffixMap."*";
		}
	}
	else { Write-Warning "The 'BranchSuffixMap' property is undefined."; }

	# Saving the [Manifest].
	if (-not ($DoNotSave)) { $Manifest | Save-NcrementManifest; }

	return $Manifest;
}

function ConvertTo-Version([string]$value, [int]$fallback)
{
	[int]$num = 0;
	if ([string]::IsNullOrEmpty($value))
		{ return $fallback; }

	elseif ([int]::TryParse($value, [ref]$num))
		{ return $num; }

	else
		{ return [System.DateTime]::UtcNow.ToString($value); }
}