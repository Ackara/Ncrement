Import-Module "$(Split-Path $PSScriptRoot -Parent)\config.psm1" -Force
$context = New-TestEnvironment;
Import-Module $context.ModulePath;

Describe "ConvertTo-NuGetProperties" {
	Push-Location $context.TestDir;
	It "should convert a [Manifest] object to a valid nuget value-pair string" {
		$result = Get-BuildboxManifest "$($context.TestDataDir)\manifest-full.json" | ConvertTo-NuGetProperties;
		{ Approve-Text $result "converto-nuget.json" } | Should Not Throw;
	}
	Pop-Location;
}