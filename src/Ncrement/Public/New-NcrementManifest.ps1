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

	return New-Object PSObject -Property @{
		"Path"="";
		"Id"=$Id;
		"Version"=New-Object PSObject -Property @{
			"Major"=0;
			"Minor"=0;
			"Patch"=1;
			"Suffix"="";
		};

		"Name"=$Name;
		"Summary"="";
		"Description"=$Description;
		"Author"=$Author;
		"Company"=$Company;
		"Copyright"=$Copyright;

		"RepositoryUrl"=$RepositoryUrl;
		"Website"=$Website;
		"License"=$License;
		"Icon"=$Icon;

		"ReleaseNotes"=$ReleaseNotes;

		"BranchSuffixMap"=@{
			"master"="";
			"*"="alpha";
		};
	};
}