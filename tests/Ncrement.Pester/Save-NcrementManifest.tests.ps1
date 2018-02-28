Import-Module "$PSScriptRoot\test.psm1" -Force;

Describe "Save-NcrementManifest" {
	Context "Help" {
		It "can display help menu" {
			$help = (help Save-NcrementManifest -Full | Out-String);
			$help | Should Not BeNullOrEmpty;
			#(Approve-Results $help "Save-NcrementManifest_help.txt") | Should Be $true;
		}
	}

	Context "Command" {
		$context = New-TestEnvironment;
		$manifest = Get-NcrementManifest $context.TestFiles;
		$manifest.Name = "Automated Test";
		$manifest.Version.Major = 2;
		$manifest.Version.Minor = 2;
		$manifest.Version.Patch = 2;

		Push-Location $context.TestDir;

		It "should save [Manifest] at default location" {
			$manifest.Path = "";
			$path = $manifest | Save-NcrementManifest;
			$path | Should Be "$PWD\manifest.json";
			$path | Should Exist;
		}

		It "should save [Manifest] when the file do not exist." {
			$path = Save-NcrementManifest "new_manifest.json" $manifest;
			$path | Should Be "$PWD\new_manifest.json";
			$path | Should Exist;
		}

		It "should save [Manifest] when directory is passed" {
			$path = $manifest | Save-NcrementManifest $env:TEMP;
			$path | Should Be "$env:TEMP\manifest.json";
			$path | Should Exist;
		}

		It "should save [Manifest] that was nested in a json object." {
			$path = $manifest | Save-NcrementManifest "$($context.TestFiles)\nested_manifest.json";
			(Approve-File $path) | Should Be $true;
		}

		It "should serialize all expected fields" {
			$path = $manifest | Save-NcrementManifest;
			(Get-Content $path | Out-String) | Approve-Results | Should Be $true;
		}

		Pop-Location;
	}
}