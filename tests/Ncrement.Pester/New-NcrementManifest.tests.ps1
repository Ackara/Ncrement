Import-Module "$PSScriptRoot\test.psm1" -Force;

Describe "New-NcrementManifest" {
	$context = New-TestEnvironment;

	Context "Help" {
		It "can display help menu." {
			$help = (help New-NcrementManifest -Full | Out-String);
			$help | Should Not BeNullOrEmpty;
			#Approve-Results $help "New-NcrementManifest.help" | Should Be $true;
		}
	}

	Context "Command" {
		$sut = New-NcrementManifest -Id "Ncrement";
		It "should have all expected fields." {
			$json = $sut | ConvertTo-Json | Out-String;
			$passed = Approve-Results $json;
			$passed | Should Be $true;
		}
	}
}