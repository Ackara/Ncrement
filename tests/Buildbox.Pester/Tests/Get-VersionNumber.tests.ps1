Import-Module "$(Split-Path $PSScriptRoot -Parent)\config.psm1" -Force
$context = New-TestEnvironment -useTemp;
Import-Module $context.ModulePath -Force;

Describe "Get-VersionNumber" {
	Push-Location $context.TestDir;
	&git init;
	&git add TestData/;
	&git commit -m "init";
	&git branch "fake";
	&git checkout "fake";

	$sampleFile = "$($context.TestDataDir)\manifest.json";
	
	Context "Version Number" {
		It "should return the full version number" {
			$ver = Get-BuildboxManifest $sampleFile | Get-VersionNumber "dev";
			$ver | Should Be "1.2.3-preview";
		}

		It "should return the version number only when the switch is present" {
			$ver = Get-BuildboxManifest $sampleFile | Get-VersionNumber "dev" -NumberOnly;
			$ver | Should Be "1.2.3";
		}

		It "should return the version number only when the suffix is null" {
			$ver = Get-BuildboxManifest $sampleFile | Get-VersionNumber "master";
			$ver | Should Be "1.2.3";
		}
	}

	Context "Version Suffix" {
		It "should return the correct suffix" {
			$suffix = Get-BuildboxManifest $sampleFile | Get-VersionNumber "dev" -SuffixOnly;
			$suffix | Should Be "preview";
		}

		It "should find the branch name automatically when the branch name is not passed." {
			$suffix = Get-BuildboxManifest $sampleFile | Get-VersionNumber -SuffixOnly;
			$suffix | Should Be "alpha";
		}

		It "should return empty string when the BranchSuffixMap property is null." {
			$suffix = Get-BuildboxManifest "$($context.TestDataDir)\nosuffix_manifest1.json" | Get-VersionNumber -SuffixOnly;
			$suffix | Should Be "";
		}
	}
	Pop-Location;
}