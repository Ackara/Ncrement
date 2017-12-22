Import-Module "$(Split-Path $PSScriptRoot -Parent)\config.psm1" -Force
$context = New-TestEnvironment;
Import-Module $context.ModulePath -Force;

Describe "Get-BuildboxManifest" {
	Push-Location $context.TestDir;
	Context "Deserialization" {
		$sampleFile = Get-Item "$($context.TestDataDir)\manifest.json";
		It "should deserialize a valid json file." {
			$result = Get-BuildboxManifest $sampleFile | ConvertTo-Json;
			{ Approve-Text $result "get-manifest1.json" } | Should Not Throw;
		}

		It "should be able to invoke [Manifest] methods" {
			$manifest = $sampleFile | Get-BuildboxManifest;
			$manifest.GetVersionSuffix("*") | Should Be "alpha";
		}

		It "should throw an exception when the specified file do not exist" {
			{ Get-BuildboxManifest -p "$($context.TestDir)\.nonexist.json" } | Should Throw;
		}
	}

	Pop-Location;
}