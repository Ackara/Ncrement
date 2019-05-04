<#
.SYNOPSIS
Creates a new [Manifest] object.

.DESCRIPTION
This function creates a new [Manifest] object.

.EXAMPLE
New-NcrementManifest | ConvertTo-Json | Out-File "C:\app\manifest.json";
This example, creates a new [Manifest] and saves to a file.
#>
function New-NcrementManifest()
{
	return @"
	{
		"name": null,
		"author": null,
		"company": null,
		"copyright": "Copyright $(Get-Date | Select-Object -ExpandProperty Year)",

		"website": null,
		"repository": null,
		"icon": null,
		"tags": null,
		"license": null,
		"releaseNotes": null,

		"version": { "major": 0, "minor": 0, "patch": 0 },
		"branchSuffixMap": { "master": "", "*": "beta" }
	}
"@ | ConvertFrom-Json;
}