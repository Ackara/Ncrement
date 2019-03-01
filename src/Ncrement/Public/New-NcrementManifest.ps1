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
		"id": null,
		"name": null,
		"author": null,
		"company": null,
		"copyright": null,
		"website": null,
		"license": null,
		"repository": null,
		"icon": null,
		"tags": null,
		"releaseNotes": null,

		"version": { "major": 0, "minor": 0, "patch": 1 },
		"branchSuffixMap": { "master": "", "*": "rc" }
	}
"@ | ConvertFrom-Json;
}