function Edit-PowershellManifest
{
	[CmdletBinding(ConfirmImpact = "Medium", SupportsShouldProcess)]
	Param(
		[Parameter(Mandatory)]
		$Manifest,

		[Parameter(Mandatory, ValueFromPipeline)]
		$InputObject
	)

	BEGIN
	{
		$path = ConvertTo-Path $Manifest;
		if ($path -and (Test-Path $path -PathType Leaf)) { $Manifest = Get-Content $path | ConvertFrom-Json; }
	}

	PROCESS
	{
		[string]$path = ConvertTo-Path $InputObject;
		if ($path.EndsWith(".psd1") -and (Test-ModuleManifest $path) -and $PSCmdlet.ShouldProcess($InputObject))
		{
			$version = ConvertTo-NcrementVersionNumber $Manifest | Select-Object -ExpandProperty Version;
			Update-ModuleManifest $path `
			-ModuleVersion $version `
			-Author ($Manifest.Author | Get-IfNull $env:USERNAME) `
			-CompanyName ($Manifest.Company | Get-IfNull $env:USERNAME) `
			-Description ($Manifest.Description | Get-IfNull $null) `
			-Copyright ($Manifest.Copyright | Get-IfNull $null) `
			-ProjectUri ($Manifest.Website | Get-IfNull $null) `
			-LicenseUri ($Manifest.License | Get-IfNull $null) `
			-IconUri ($Manifest.Icon | Get-IfNull $null) `
			-ReleaseNotes ($Manifest.ReleaseNotes | Get-IfNull $null) `
			-Tags (($Manifest.Tags | Get-IfNull $null).Split(' '));

			return $InputObject;
		}

		return $false;
	}
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