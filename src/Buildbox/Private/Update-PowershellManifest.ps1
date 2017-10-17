function Update-PowershellManifest()
{
	<#
	.SYNOPSIS
	This function updated a powershell manifest using a specified Acklann.Buildbox.Versioning.Manifest instance.

	.DESCRIPTION
	This function will updated a powershell manifest using a specified Acklann.Buildbox.Versioning.Manifest instance. Returns true if the operation succeeded false if otherwise.

	.PARAMETER Path
	The of the powershell module manifest (.psd1).

	.PARAMETER Manifest
	An Acklann.Buildbox.Versioning.Manifest instance.

	.OUTPUTS
	System.Boolean

	.EXAMPLE
	Update-PowershellManifest $manifest "C:\modules\helloworld.psd1";
	This example updates the specified powershell manifest file using the given Aclann.Buildbox.SemVer.Manifest object.
	#>

	Param(
		[Alias('p')]
		[Parameter(Mandatory, ValueFromPipeline, Position = 2)]
		$Path,

		[Alias('m')]
		[Parameter(Mandatory, Position = 1)]
		$Manifest
	)

	Update-ModuleManifest $Path `
	-ModuleVersion $Manifest.Version.ToString() `
	-Description $Manifest.Description `
	-Author $Manifest.Authors `
	-CompanyName $Manifest.Owner `
	-Copyright $Manifest.Copyright `
	-ProjectUri $Manifest.ProjectUrl `
	-LicenseUri $Manifest.LicenseUri `
	-IconUri $Manifest.IconUri `
	-Tags $Manifest.Tags.Split(' ', ';', ',');

	return Test-ModuleManifest $Path -ErrorAction Stop;
}