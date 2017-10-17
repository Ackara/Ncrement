Import-Module "$PSScriptRoot\helper.psm1" -Force;
$testContext = New-TestEnviroment;
Import-Module $testContext.Module -Force;

Describe "Buildbox" {
	Context "Edit-FlywayConf" {
		$url = "jdbc:mysql://localhost/buildbox";
		$usr = "buildbox";
		$pwd = ConvertTo-SecureString "pa551" -AsPlainText -Force;
		$loc = @("C:\Temp\", "C:\Temp\flyway");

		$result1 = $testContext.DownloadDir | Install-Flyway | Edit-FlywayConf -Url $url -u $usr -p $pwd -l $loc -WhatIf;
		$configFile = "$($testContext.TestResultsDir)\editflyway.conf";
		$flyway = Install-Flyway $testContext.DownloadDir;
		Copy-Item -Path $flyway.configFile -Destination $configFile -Force;
		$result2 = Edit-FlywayConf $configFile -Url $url -u $usr -p $pwd -l $loc;
		
		It "Edit-FlywayConf should return the full path to 'flyway.conf'." {
			$result1 | Should Exist;
		}

		It "Edit-FlywayConf should edit a 'flyway.conf' file using the given values." {
			Approve-File $result2 "Edit-FlywayConf" | Should Be $true; 
		}

		It "Edit-FlywayConf should halt editing the 'flyway.conf' file when the '-WhatIf' switch is present."{
			(Compare-Object $(Get-Content $result1) $(Get-Content $result2)) | Should Not Be $null;
		}
	}
}

if (Get-Module Buildbox) { Remove-Module BuildBox; }