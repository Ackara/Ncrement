Import-Module "$PSScriptRoot\helper.psm1" -Force;
$testContext = New-TestEnviroment;
Import-Module $testContext.module -Force;

Describe "Edit-FlywayConf" {
	$url = "jdbc:mysql://localhost/buildbox";
	$usr = "buildbox";
	$pwd = ConvertTo-SecureString "pa551" -AsPlainText -Force;
	$loc = @("C:\Temp\", "C:\Temp\flyway");

	$result1 = $testContext.downloadDir | Install-Flyway | Edit-FlywayConf -Url $url -u $usr -p $pwd -l $loc -WhatIf;
	$configFile = "$($testContext.testResultsDir)\editflyway.conf";
	$flyway = Install-Flyway $testContext.downloadDir;
	Copy-Item -Path $flyway.configFile -Destination $configFile -Force;
	$result2 = Edit-FlywayConf $configFile -Url $url -u $usr -p $pwd -l $loc;
	
	It "should return the full path to 'flyway.conf'." {
		$result1 | Should Exist;
	}

	It "should edit a 'flyway.conf' file using the given values." {
		Approve-File $result2 $MyInvocation.MyCommand.Name | Should Be $true; 
	}

	It "should halt editing the 'flyway.conf' file when the '-WhatIf' switch is present."{
		(Compare-Object $(Get-Content $result1) $(Get-Content $result2)) | Should Not Be $null;
	}
}