<#
.SYNOPSIS
Instantiates a new [Manifest] object.

.PARAMETER Id
The id.

.PARAMETER Version
The version number.

.PARAMETER Product
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

.PARAMETER ProjectUrl
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
		[string]$Product,
		[string]$Description,
		[string]$Author,
		[string]$Company,
		[string]$Copyright,

		[string]$RepositoryUrl,
		[string]$ProjectUrl,
		[string]$License,
		[string]$Icon,

		[string]$ReleaseNotes
	)

	return New-Object PSObject -Property @{
		"Id"=$Id;
		"Version"=New-Object PSObject -Property @{
			"Major"=0;
			"Minor"=0;
			"Patch"=1;
			"Suffix"="";
		};

		"Product"=$Product;
		"Description"=$Description;
		"Author"=$Author;
		"Company"=$Company;
		"Copyright"=$Copyright;

		"RepositoryUrl"=$RepositoryUrl;
		"ProjectUrl"=$ProjectUrl;
		"License"=$License;
		"Icon"=$Icon;

		"ReleaseNotes"=$ReleaseNotes;

		"BranchSuffixMap"=@{
			"master"="";
			"*"="rc";
		};
	};
}
