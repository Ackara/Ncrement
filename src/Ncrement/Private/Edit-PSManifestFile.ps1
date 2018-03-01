<#
.SYNOPSIS
Updates all '.psd1' files in a directory using the in the specified [Manifest] object.

.PARAMETER $Manifest
The [Manifest] object.

.PARAMETER Path
The project directory.
#>

function Edit-PSManifestFile
{
	Param(
		[Parameter(Mandatory, ValueFromPipeline)]
		$Manifest,

		[string]$Path
	)

	$modifiedFiles = [System.Collections.ArrayList]::new();
	foreach ($file in (Get-ChildItem $Path -Recurse -Filter "*.psd1" | Select-Object -ExpandProperty FullName))
	{
		if ($PSCmdlet.ShouldProcess($file))
		{
			
			Update-ModuleManifest $file `
			-ModuleVersion ($Manifest | Convert-NcrementVersionNumberToString) `
			-Author ($Manifest.Author | Get-IfNull $env:USERNAME) `
			-CompanyName ($Manifest.Company | Get-IfNull $env:USERNAME) `
			-Description ($Manifest.Description | Get-IfNull $null) `
			-Copyright ($Manifest.Copyright | Get-IfNull $null) `
			-ProjectUri ($Manifest.Website | Get-IfNull $null) `
			-LicenseUri ($Manifest.License | Get-IfNull $null) `
			-IconUri ($Manifest.Icon | Get-IfNull $null) `
			-ReleaseNotes ($Manifest.ReleaseNotes | Get-IfNull $null) `
			-Tags (($Manifest.Tags | Get-IfNull $null).Split(' '));
		}

		$modifiedFiles.Add($file) | Out-Null;
	}


	return $modifiedFiles;
}

function Get-IfNull
{
	Param(
		[Parameter(ValueFromPipeline)]
		[string]$value, 
		
		[Parameter(Position=0)]
		$fallback
	)

	if ([string]::IsNullOrEmpty($value)) { return $fallback; }
	else { return $value; }
}