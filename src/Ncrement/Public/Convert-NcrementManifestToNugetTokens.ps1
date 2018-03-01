<#
.SYNOPSIS
Serializes a [Manifest] object to a nuget tokens.

.PARAMETER Manifest
The [Manifest] object.

.INPUTS
[Manifest]

.OUTPUTS
[String]

.EXAMPLE
&nuget -Properties "$(Get-NcrementManifest | Convert-NcrementManifestToNugetTokens)";
In this example, the [Manifest] is being piped to the function to be used as the value for the 'nuget.exe' -Properties argument.

.LINK
Get-NcrementManifest

.LINK
New-NcrementManifest
#>

function Convert-NcrementManifestToNugetTokens([Parameter(Mandatory, ValueFromPipeline)]$Manifest)
{
	$token = [System.Text.StringBuilder]::new();
	$exclusionList = @("Path", "BranchSuffixMap", "Version");

	foreach ($prop in $Manifest.PSObject.Properties)
	{
		if (($exclusionList -notcontains $prop.Name) -and (-not [string]::IsNullOrEmpty($prop.Value)))
		{
			$token.AppendFormat("{0}={1};", $prop.Name, $prop.Value) | Out-Null;
		}
	}

	return $token.ToString();
}

Set-Alias -Name "n-token" -Value  "Convert-NcrementManifestToNugetTokens";
Set-Alias -Name "ConvertTo-NuGetTokens" -Value  "Convert-NcrementManifestToNugetTokens";