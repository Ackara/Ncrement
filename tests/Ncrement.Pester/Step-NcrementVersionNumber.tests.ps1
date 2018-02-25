Import-Module "$PSScriptRoot\test.psm1" -Force;

Describe "Step-NcrementVersionNumber" {
	Context "Help" {
		$help = (help Step-NcrementVersionNumber | Out-String);
		$help | Should Not BeNullOrEmpty;
		Approve-Results $help | Should Be $true;
	}

	Context "Commnad" {
		$context = New-TestEnvironment;
		
		It "should increment patch number." {
			$manifest = $context.TestFiles | Get-NcrementManifest;

			$result = $manifest | Step-NcrementVersionNumber -Fix;
			$result.Major | Should Be 1;
			$result.Minor | Should Be 2;
			$result.Patch | Should Be 4;
			$result.Suffix | Should Be 'rc';
		}

		It "should increment minor number." {
			$result = $manifest | Step-NcrementVersionNumber "master" -Feature;
			$result.Major | Should Be 1;
			$result.Minor | Should Be 3;
			$result.Patch | Should Be 0;
			$result.Suffix | Should Be '';
		}

		It "should increment patch number." {
			$result = $manifest | Step-NcrementVersionNumber -Break;
			$result.Major | Should Be 2;
			$result.Minor | Should Be 0;
			$result.Patch | Should Be 0;
		}
	}
}
