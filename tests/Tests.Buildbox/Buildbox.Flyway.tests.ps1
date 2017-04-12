$rootDir = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent;
$module = "$rootDir\src\Buildbox.Flyway\buildbox.flyway.psm1";
Import-Module $module -Force;

$testResultsDir = "$rootDir\tests\TestResults";
if (Test-Path $testResultsDir -PathType Container)
{ Remove-Item $testResultsDir -Recurse; }
New-Item $testResultsDir -ItemType Directory | Out-Null;

$sampleDir = "$PSScriptRoot\samples\flyway";
$defaultConfig = "$(Split-Path $module -Parent)\bin\flyway*\conf\flyway.conf";
$sampleConfig = "$testResultsDir\flyway.mock.conf";

Copy-Item "$sampleDir\flyway.conf" $sampleConfig -Force;

function Test-FlywayProperty($Path, $Key, $Value="\w+")
{
	$regex = New-Object Regex("(#\s*)?flyway\.$Key=$Value");
	$content = Get-Content $Path | Out-String;

	if ($regex.IsMatch($content))
	{
		return -not $regex.Match($content).Value.StartsWith('#');
	}
	else { return $false; }
}

# ----- TESTS -----

Describe "Install-Flyway" {
	$flywayDir = "$(Split-Path $module -Parent)\bin";
	#Remove-Item $flywayDir -Recurse -Force;

	$flywayExe = Install-Flyway;

	It "should download flyway toolset." {
		$flywayExe | Should Exist;
		$defaultConfig | Should Exist;
	}
}

Describe "Edit-FlywayConfig" {
	
	It "should set a property when it is commented out." {
		$user = "ackara";
		Edit-FlywayConfig $sampleConfig -User $user;
		Test-FlywayProperty $sampleConfig "user" $user | Should Be $true;
	}

	It "should not add value to config file when it does not exist." {
		$pass = "pa55w0rd";
		Edit-FlywayConfig $sampleConfig -Password $pass;
		Test-FlywayProperty $sampleConfig "password" $pass | Should Be $false;
	}

	It "should overwrite a property when it already exist." {
		Edit-FlywayConfig $sampleConfig -Url "changed";
		Test-FlywayProperty $sampleConfig "url" "changed" | Should Be $true;
	}

	It "should overwrite a property in the default config when the 'Path' is not specified." {
		Install-Flyway;
		Edit-FlywayConfig -User "ackara";
		Test-FlywayProperty $defaultConfig "user" "ackara";
	}
}

Describe "Copy-FlywayConfig" {
	if (Test-Path $sampleConfig -PathType Leaf)
	{ Remove-Item $sampleConfig -Force; }
	
	It "should copy 'flyway.conf' file to specified location." {
		Copy-FlywayConfig $sampleConfig;
		$sampleConfig | Should Exist;
	}
}

Describe "Invoke-Flyway" {
	if (Test-Path $sampleConfig -PathType Leaf) 
	{ Remove-Item $sampleConfig; }

	Install-Flyway;
	Copy-FlywayConfig $sampleConfig;
	Edit-FlywayConfig $sampleConfig -Url "jdbc:sqlite:$sampleDir\mock.db3";
	Edit-FlywayConfig $sampleConfig -User "ackara";
	Edit-FlywayConfig $sampleConfig -Password "password1";

	$cred = New-Object pscredential("zorc", ("pasdfkaj" | ConvertTo-SecureString -AsPlainText -Force));
	
	It "should return a [FlywayResults] object with its 'State' property set to Empty" {
		$result = Invoke-Flyway "info" $sampleConfig;
		$result.RawOutput | Should Not BeNullOrEmpty;
		$result.State | Should Be Empty;
	}
	
	It "should return a [FlywayResults] object with its 'State' property set to Pending" {
		"create table [user]()" | Out-File "$testResultsDir\V1__baseline.sql" -Encoding utf8;
		$result = Invoke-Flyway "info" -Url "jdbc:sqlite:$sampleDir\mock.db3" -Locations $testResultsDir -Credential $cred;
		$result.State | Should be Pending;
	}

	It "should return a [FlywayResults] object with its 'State' property set to None" {
		"create table [user](id int)" | Out-File "$testResultsDir\V1__baseline.sql" -Encoding utf8;
		$mockDb = "$testResultsDir\mock.db3";
		Copy-Item "$sampleDir\mock.db3" $mockDb;
		$result = Invoke-Flyway "migrate" -Url "jdbc:sqlite:$mockDb" -Locations $testResultsDir -Credential $cred;
		$result.State | Should be None;
	}
}