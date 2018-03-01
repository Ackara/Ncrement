Import-Module "$PSScriptRoot\test.psm1" -Force;

Describe "Convert-NcrementManifestToNugetTokens" {
	Context "Help" {
		It "display help menu" {
			$help = (help Convert-NcrementManifestToNugetTokens -Full | Out-String);
			$help | Should Not BeNullOrEmpty;
			#Approve-Results $help "Convert-NcrementManifestToNugetTokens_help" | Should Be $true;
		}
	}

	Context "Command" {
		$context = New-TestEnvironment;
		$manifest = Get-NcrementManifest $context.TestFiles;

		It "should return expected name-value string." {
			$tokens = $manifest | Convert-NcrementManifestToNugetTokens;
			$tokens | Should Not BeNullOrEmpty;
			Approve-Results $tokens | Should Be $true;
		}
	}
}