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

	# Save secrets
	if ($Secrets.Count -ge 1)
	{
		$Secrets | ConvertTo-Json | Out-File "$PSScriptRoot\secrets.json" -Encoding utf8;
	}

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

Task "Update-Manifest" -alias "version" -description "Increment the manifest version number." `
-depends @("restore") -action {
	# Increment version number
	$manifest = Get-Content "$PSScriptRoot\manifest.json" | Out-String | ConvertFrom-Json;
	$version = "$($manifest.version.major).$($manifest.version.minor).$($manifest.version.patch)";

	$psd1 = (Get-Item "$RootDir\src\*\*.psd1").FullName;
	Update-ModuleManifest -Path $psd1 `
	-CompanyName $manifest.author `
	-Copyright $manifest.copyright `
	-ModuleVersion $version `
	-ProjectUri $manifest.url `
	-LicenseUri $manifest.license `
	-Description $manifest.description `
	-IconUri $manifest.icon `
	-Tags $manifest.tags `
	-CmdletsToExport * `
	-FunctionsToExport * `
	-Author $manifest.author;

	Exec { &git tag v$version; }
}

#endregion

#region ----- PUBLISHING -----

Task "Package-Application" -alias "pack" -description "Package module as a nuget package." `
-depends @("restore") -action {
	if (Test-Path $ArtifactsDir) { Remove-Item $ArtifactsDir -Recurse -Force; }
	New-Item $ArtifactsDir -ItemType Directory | Out-Null;

	$manifest = Get-Content "$PSScriptRoot\manifest.json" | Out-String | ConvertFrom-Json;
	$version = "$($manifest.version.major).$($manifest.version.minor).$($manifest.version.patch)";
	
	$props = "";
	$props += "version=$version;";
	$props += "author=$($manifest.author);";
	$props += "iconUri=$($manifest.icon);";
	$props += "projectUrl=$($manifest.url);";
	$props += "licenseUri=$($manifest.license);";
	$props += "copyright=$($manifest.copyright);"
	$props += "tags=$($manifest.tags);";
	$props += "description=$($manifest.description)";

	$nuspec = (Get-Item "$PSScriptRoot\*.nuspec").FullName;
	Exec { &$nuget pack $nuspec -OutputDirectory $ArtifactsDir -Properties $props; }
}

Task "Publish-Module" -alias "push" -description "Publish module to 'powershellgallery.com' and 'nuget.org'" `
-depends @("test", "pack") -action {
	$psd1 = (Get-Item "$RootDir\src\*\*.psd1").FullName;
	$nupkg = (Get-Item "$ArtifactsDir\*.nupkg").FullName;

	$keys = Get-Content "$PSScriptRoot\secrets.json" | Out-String | ConvertFrom-Json;
	Exec { &$nuget push $nupkg -ApiKey $keys.nugetKey; }
	Publish-Module -Path $psd1 -NuGetApiKey $keys.psGalleryKey;
}

#endregion

#region ----- FUNCTIONS -----



#endregion