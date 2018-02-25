Import-Module "$PSScriptRoot\test.psm1";

Describe "Get-NcrementManifest" {
	$context = New-TestEnvironment;

	Context "Help"{
		It "can display help menu." {
			$help = (help Get-NcrementManifest -Full | Out-String);
			$help | Should Not BeNullOrEmpty;
			#Approve-Results $help | Should Be $true;
		}
	}

	Context "Command" {
		Push-Location $context.TestFiles;

		It "should load a [Manifest] from .json file." {
			$result = Get-NcrementManifest;
			$result.Version.Major | Should Be 1;
			$result.Version.Minor | Should Be 2;
			$result.Version.Patch | Should Be 3;
			$result.BranchSuffixMap.'master' | Should Be '';
		}

		It "should load a [Manifest] from when nested in json object." {
			$result = "nested_manifest.json" | Get-NcrementManifest;
			$result.Company | Should Not BeNullOrEmpty;
			$result.Author | Should Not BeNullOrEmpty;
			$result.Path | Should Not BeNullOrEmpty;
		}

		It "should load a [Manifest] from specified directory." {
			$result = Get-NcrementManifest $PWD;
			$result.ProjectUrl | Should Not BeNullOrEmpty;
			$result.RepositoryUrl | Should Not BeNullOrEmpty;
		}

		It "should create a [Manifest] when the file do not exist." {
			$newPath = "$($context.testDir)\new_manifest.json";
			if (Test-Path $newPath) { Remove-Item $newPath -Force; }

			$result = Get-NcrementManifest $newPath -Force;
			$newPath | Should Exist;
			$result | Should Not Be $null;
			$result.Version | Should Not Be $null;
		}

		It "should throw when specified path do not exist." {
			{ Get-NcrementManifest "$PWD\none.json" } | Should Throw;
		}

		Pop-Location;
	}
}