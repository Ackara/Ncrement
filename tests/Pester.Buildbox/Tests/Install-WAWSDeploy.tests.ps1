Import-Module "$PSScriptRoot\helper.psm1" -Force;
$testContext = New-TestEnviroment;
Import-Module $testContext.Module -Force;

Describe "Buildbox" {
	Context "Install-WAWSDeploy" {
		$installDir = $testContext.DownloadDir;
		$result1 = Install-WAWSDeploy $installDir;
		$result2 = $installDir | Install-WAWSDeploy;

		It "should download WAWSDeploy at the specified directory." {
		    $result1 | Should Exist;
		}

		It "should return existing path to WAWSDeploy when its on disk"{
			$result2 | Should Be $result1;
		}
	}
}

if (Get-Module Buildbox) { Remove-Module BuildBox; }