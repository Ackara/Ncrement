function New-NcrementManifest()
{
	@"
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