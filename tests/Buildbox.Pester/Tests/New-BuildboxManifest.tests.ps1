Import-Module "$(Split-Path $PSScriptRoot -Parent)\config.psm1" -Force
$context = New-TestEnvironment;
Import-Module $context.ModulePath -Force;

Describe "New-BuildboxManifest" {
	Push-Location $context.TestDir;
	Context "Can Create File" {
		It "should create a new 'manifest.json' when no args are passed." {
			$manifest = New-BuildboxManifest;
			$manifest.Path | Should Exist;
		}

		It "should thow an exception when a existing file is being overwritten." {
			{ New-BuildboxManifest } | Should Throw;
		}

		It "should overwrite an existing 'manifest.json' file." {
			$manifest = New-BuildboxManifest -Force;
			$manifest.Path | Should Exist;
		}
	}

	Context "Has Required Fields" {
		$manifest = New-BuildboxManifest "$PWD\new-manifest1.json" -Force;
		
		It "should have all expected fields when serialized" {
			{ Approve-File($manifest.Path) } | Should Not Throw;
		}

		It "should be of type Manifest" {
			$manifest.GetType() | Should Be Manifest;
		}
	}
	Pop-Location;
}