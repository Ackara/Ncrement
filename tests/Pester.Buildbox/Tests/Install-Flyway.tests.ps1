Import-Module "$PSScriptRoot\helper.psm1" -Force;
$testContext = New-TestEnviroment;
Import-Module $testContext.module -Force;

Describe "Install-Flyway" {
	$installDir = $testContext.downloadDir;
	Write-Host $testContext.downloadDir;
	$result1 = $installDir | Install-Flyway;
	$result2 = Install-Flyway $installDir;

	It "should download the flyway cli." {
		$result1.fileName | Should Exist;
		$result1.configFile | Should Exist;
	}

	It "should return the path to an existing flyway installation."{
		$result2.fileName | Should Be $result1.fileName;
	}
}