Import-Module "$PSScriptRoot\helper.psm1" -Force;
$testContext = New-TestEnviroment;
Import-Module $testContext.Module -Force;

Describe "Buildbox" {
	Context "Get-BuildboxManifest" {
		It "Get-BuildboxManifest should return the manifest object from an existing file." {
			try 
			{
				Push-Location $testContext.TestResultsDir;
				New-BuildboxManifest;
				$result = Get-BuildboxManifest;
				
				$result.FullPath | Should Exist;
				$result | Should BeOfType [Acklann.Buildbox.SemVer.Manifest];
			}
			finally { Pop-Location; }
		}

		It "Get-BuildboxManifest should throw an exception when the given file do not exist" {
			{ "$($testContext.TestResultsDir)\exception.json" | Get-BuildboxManifest } | Should Throw;
		}
	}
}