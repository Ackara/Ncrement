Import-Module "$PSScriptRoot\test.psm1" -Force;

Describe "Step-NcrementVersionNumber" {
	Context "Help" {
		$help = (help Step-NcrementVersionNumber -Full | Out-String);

		It "can display help menu" {
			$help | Should Not BeNullOrEmpty;
			#Approve-Results $help | Should Be $true;
		}
	}

	Context "Commnad" {
		$context = New-TestEnvironment;
		$manifest = $context.TestFiles | Get-NcrementManifest;

		It "should increment patch number." {
			$result = $manifest | Step-NcrementVersionNumber -Fix;
			$result.Version.Major | Should Be 1;
			$result.Version.Minor | Should Be 2;
			$result.Version.Patch | Should Be 4;
			$result.Version.Suffix | Should Be 'rc';
		}

		It "should increment minor number." {
			$result = $manifest | Step-NcrementVersionNumber "master" -Feature;
			$result.Version.Major | Should Be 1;
			$result.Version.Minor | Should Be 3;
			$result.Version.Patch | Should Be 0;
			$result.Version.Suffix | Should BeNullOrEmpty;
		}

		It "should increment major number." {
			$result = $manifest | Step-NcrementVersionNumber -Break;
			$result.Version.Major | Should Be 2;
			$result.Version.Minor | Should Be 0;
			$result.Version.Patch | Should Be 0;
		}

		It "should save modified [Manifest] back to existing file." {
			$json = Get-Content $manifest.Path | Out-String | ConvertFrom-Json;
			$json.Version.Major | Should Not Be 2;
			$json.Version.Minor | Should Not Be 0;
			$json.Version.Patch | Should Not Be 0;
		}
	}
}