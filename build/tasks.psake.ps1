$seperator = "----------------------------------------------------------------------";
FormatTaskName "$seperator`r`n  {0}`r`n$seperator";

Properties {
	# Constants
	$RootDir = "$(Split-Path $PSScriptRoot -Parent)";
	$ArtifactsDir = "$RootDir\artifacts";
	$Nuget = "";

	# Args
	$SkipCompilation = $false;
	$Configuration = "";
	$Secrets = @{ };
	$Major = $false;
	$Minor = $false;
	$TestName = "";
	$Branch = "";
}

Task "default" -depends @("restore", "test");

#region ----- COMPILATION -----

Task "Import-Dependencies" -alias "restore" -description "Imports the solution dependencies." `
-action {
	#  Importing the pester module.
	$modulePath = "$RootDir\tools\Pester\*\*.psd1";
	if (-not (Test-Path $modulePath))
	{
		Save-Module "Pester" -RequiredVersion 3.4.6 -Path "$RootDir\tools";
	}
	Import-Module $modulePath -Force;
	Write-Host "   * imported module Pester.";
}

Task "Run-Tests" -alias "test" -description "Invoke all tests within the 'tests' folder." `
-depends @("restore") -action {
	$totalFailedTests = 0;
	foreach ($testFile in (Get-ChildItem "$RootDir\tests\*.pester" -Recurse -Filter "$TestName*.tests.ps1"))
	{
		$result = Invoke-Pester $testFile.FullName -PassThru;
		$totalFailedTests += $result.FailedCount;
	}
	if ($totalFailedTests -ge 1) { throw "'$totalFailedTests' TESTS FAILED!"; }
}

#endregion

#region ----- PUBLISHING -----

#endregion

#region ----- FUNCTIONS -----

#endregion