Import-Module "$PSScriptRoot\helper.psm1" -Force;
$testContext = New-TestEnviroment;
Import-Module $testContext.Module -Force;

Describe "Buildbox" {
	Context "Install-Flyway" {
		$installDir = $testContext.DownloadDir;
		Write-Host $testContext.DownloadDir;
		$result1 = $installDir | Install-Flyway;
		$result2 = Install-Flyway $installDir;

		It "Install-Flyway should download the flyway cli." {
			$result1.fileName | Should Exist;
			$result1.configFile | Should Exist;
		}

		It "should return the path to an existing flyway installation."{
			$result2.fileName | Should Be $result1.fileName;
		}
	}
}

if (Get-Module Buildbox) { Remove-Module BuildBox; }