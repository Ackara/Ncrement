<#
.SYNOPSIS
Instantiates a new [Manifest] object.

.PARAMETER Id
The id.

.PARAMETER Version
The version number.

.PARAMETER Name
The product name.

.PARAMETER Description
The product description.

.PARAMETER Author
The author.

.PARAMETER Company
The owner(s).

.PARAMETER Copyright
The copyright.

.PARAMETER License
The license.

.PARAMETER Website
The product url.

.PARAMETER RepositoryUrl
The source control url.

.PARAMETER Icon
The product logo.

.PARAMETER ReleaseNotes
The release notes.

.OUTPUTS
[Manifest]

.EXAMPLE
$manifest = New-NcrementManifest -Product "app_name" -Author "me and you";
This example creates a new [Manifest] object.
#>

function New-NcrementManifest
{
	Param(
		[string]$Id = ([Guid]::NewGuid().ToString()),

		[Alias("title", "productName", "product")]
		[string]$Name,
		[string]$Description,

		[string]$Author,
		[string]$Company,
		[string]$Copyright,

		[string]$RepositoryUrl,
		[string]$Website,
		[string]$License,
		[string]$Icon,

		[string]$ReleaseNotes
	)

	$manifest = [Ncrement.Manifest]::new();
	$manifest.Id = $Id;
	$manifest.Name = $Name;
	$manifest.Author = $Author;
	$manifest.Company = $Company;
	$manifest.Copyright = $Copyright;
	$manifest.Description = $Description;
	$manifest.RepositoryUrl = $RepositoryUrl;
	$manifest.Website = $Website;
	$manifest.License = $License;
	$manifest.Icon = $Icon;
	$manifest.ReleaseNotes = $ReleaseNotes;

	return $manifest;
}