Import-Module "$PSScriptRoot\test.psm1" -Force;

Describe "Step-NcrementVersionNumberUsingDate" {
	Context "Help" {
		$help = (help Step-NcrementVersionNumberUsingDate -Full | Out-String);

		It "can display help menu" {
			$help | Should Not BeNullOrEmpty;
			#Approve-Results $help | Should Be $true;
		}
	}

	Context "Commnad" {
		$context = New-TestEnvironment;
		$manifest = $context.TestFiles | Get-NcrementManifest;

		It "should increment version number with date." {
			$result = $manifest | Step-NcrementVersionNumberUsingDate "yyyy" "MM";
			$result.Version.Major | Should BeGreaterThan 2017;
			$result.Version.Minor | Should BeGreaterThan 0;
			$result.Version.Patch | Should Be 4;
			$result.Version.Suffix | Should Be 'rc';
		}

		It "should increment version number with integer." {
			$result = $manifest | Step-NcrementVersionNumberUsingDate "1709" "4321" "12" "master";
			$result.Version.Major | Should Be 1709;
			$result.Version.Minor | Should Be 4321;
			$result.Version.Patch | Should Be 12;
			$result.Version.Suffix | Should BeNullOrEmpty;
		}

		It "should save modified [Manifest] back to existing file." {
			$json = Get-Content $manifest.Path | Out-String | ConvertFrom-Json;
			$json.Version.Major | Should Not Be 1709;
			$json.Version.Minor | Should Not Be 4321;
			$json.Version.Patch | Should Not Be 12;
		}
	}
}