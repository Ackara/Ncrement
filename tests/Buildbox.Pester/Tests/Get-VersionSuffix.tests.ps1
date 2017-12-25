Import-Module "$(Split-Path $PSScriptRoot -Parent)\config.psm1" -Force
$context = New-TestEnvironment -useTemp;
Import-Module $context.ModulePath -Force;

Describe "Get-VersionSuffix" {
	Push-Location $context.TestDir;
	&git init;
	&git add TestData/;
	&git commit -m "init";
	&git branch "fake";
	&git checkout "fake";

	$sampleFile = "$($context.TestDataDir)\manifest.json";

	It "should return the correct suffix" {
		$suffix = Get-BuildboxManifest $sampleFile | Get-VersionSuffix "dev";
		$suffix | Should Be "preview";
	}

	It "should find the branch name automatically when the branch name is not passed." {
		$suffix = Get-BuildboxManifest $sampleFile | Get-VersionSuffix;
		$suffix | Should Be "alpha";
	}

	It "should return empty string when the BranchSuffixMap property is null." {
		$suffix = Get-BuildboxManifest "$($context.TestDataDir)\nosuffix_manifest1.json" | Get-VersionSuffix;
		$suffix | Should Be "";
	}
	Pop-Location;
}