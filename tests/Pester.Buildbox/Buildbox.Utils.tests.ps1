#
# This is a PowerShell Unit Test file.
# You need a unit test framework such as Pester to run PowerShell Unit tests. 
# You can download Pester from http://go.microsoft.com/fwlink/?LinkID=534084
#

Import-Module "$PSScriptRoot\helper.psm1" -Force;
$rootDir = Get-RootDir;
$testResultsDir = New-TestResultsDir "utils";
$sampleDir = "$PSScriptRoot\Samples";
$modulePath = Get-Item "$rootDir\src\*.Utils\*psd1";
Import-Module $modulePath.FullName -Force;

Describe "Buildbox.Utils" {
	#Context "validate comment based help" {
	#	It "should work" {
	#		help Install-FlywayCLI -ShowWindow;
	#		help Edit-FlywayConfig -ShowWindow;
	#		help Install-WawsDeploy -ShowWindow;
	#	}
	#}

	Context "Install-FlywayCLI" {
		It "should download the flyway cli tool from 'https://flywaydb.org/' if not already downloaded." {
			$cmd = Install-FlywayCLI "$PSScriptRoot\bin";
			$cmd | Should Exist;
		}
	}

	Context "Edit-FlywayConfig" {
		It "should modify the specified 'flyway.conf' file." {
			$flywayConfig = "$testResultsDir\flyway.conf";
			$pass = "pa551" | ConvertTo-SecureString -AsPlainText -Force;
			Copy-Item "$sampleDir\flyway.conf" -Destination $flywayConfig -Force;
			Edit-FlywayConfig $flywayConfig -usr "ackara" -pwd $pass -url "mysql:localhost" -loc "c:\temp";

			Approve-File $flywayConfig "edit_flywayconfig";
		}
	}

	Context "Install-WawsDeploy" {
		It "should download the wawsdeploy cli tool from 'https://chocolatey.org' if not already downloaded." {
			$exe = Install-WawsDeploy "$PSScriptRoot\bin";
			$exe | Should Exist;
		}
	}
}