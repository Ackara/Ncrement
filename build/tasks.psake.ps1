# SYNOPSIS: This is a psake task file.
Properties {
	# Constants
	$RootDir = "$(Split-Path $PSScriptRoot -Parent)";
	$ManifestJson = "$PSScriptRoot\manifest.json";
	$SecretsJson = "$PSScriptRoot\secrets.json";
	$ArtifactsDir = "$RootDir\artifacts";
	$PoshModulesDir = "";

	# Args
	$SkipCompilation = $false;
	$Configuration = "";
	$Secrets = @{ };
	$Major = $false;
	$Minor = $false;
	$Branch = "";
}

Task "default" -depends @("Import-Dependencies", "Build-Solution", "Run-Tests");

Task "Deploy" -alias "push" -description "This task compile, test then publish the application." `
-depends @("restore", "version", "compile", "test", "pack", "publish");

#region ----- COMPILATION -----

Task "Import-Dependencies" -alias "restore" -description "This task imports all dependencies." `
-action {
	#  Importing all required powershell modules.
	foreach ($moduleId in @("Buildbox"))
	{
		$modulePath = "$PoshModulesDir\$moduleId\*\*.psd1";
		if (-not (Test-Path $modulePath))
		{
			Save-Module $moduleId -Path $PoshModulesDir;
		}
		Import-Module $modulePath -Force;
		Write-Host "   * imported the '$moduleId.$(Split-Path (Get-Item $modulePath).DirectoryName -Leaf)' powershell module.";
	}

	# Saving $Secrets to a file if available.
	if ((-not (Test-Path $SecretsJson)) -and $Secrets.Count -gt 0)
	{
		$Secrets | ConvertTo-Json | Out-File $SecretsJson -Encoding utf8;
		Write-Host "   * Added '$(Split-Path $SecretsJson -Leaf)' to project.";
	}

	# Creating a new manifest if not available.
	if (-not (Test-Path $ManifestJson))
	{
		New-BuildboxManifest $ManifestJson | Out-Null;
		Write-Host "   * Added '$(Split-Path $ManifestJson -Leaf)' to project.";
	}
}

Task "Increment-VersionNumber" -alias "version" -description "This task increments the project's version numbers" `
-depends @("restore") -action {
	$result = Get-BuildboxManifest $ManifestJson | Update-ProjectManifests "$RootDir\src" -Break:$Major -Feature:$Minor -Patch -Tag -Commit;

	Write-Host "   * Incremented version number from '$($result.OldVersion)' to '$($result.Version)'.";
	foreach ($file in $result.ModifiedFiles)
	{
		Write-Host "     * Updated $(Split-Path $file -Leaf).";
	}
}

Task "Build-Solution" -alias "compile" -description "This task compiles the solution." `
-depends @("restore") -precondition { return (-not $SkipCompilation); } -action {
	Write-LineBreak "dotnet: msbuild";
	Exec { &dotnet msbuild $((Get-Item "$RootDir\*.sln").FullName) "/p:Configuration=$Configuration" "/verbosity:minimal"; }
}

Task "Run-Tests" -alias "test" -description "This task invoke all tests within the 'tests' folder." `
-depends @("restore") -action {
	Push-Location $RootDir;
	try
	{
		# Running all MSTest tests.
		foreach ($testFile in (Get-ChildItem "$RootDir\tests\*\bin\$Configuration" -Recurse -Filter "*$(Split-Path $RootDir -Leaf)*test*.dll"))
		{
			Write-LineBreak "dotnet: vstest";
			Exec { &dotnet vstest $testFile.FullName; }
		}

		# Running all Pester tests.
		$testsFailed = 0;
		foreach ($testFile in (Get-ChildItem "$RootDir\tests\*\" -Recurse -Filter "*tests.ps1"))
		{
			Write-LineBreak "pester";
			$results = Invoke-Pester -Script $testFile.FullName -PassThru;
			$testsFailed += $results.FailedCount;
		}
		if ($testsFailed -ge 1) { throw "FAILED $testsFailed Pester tests."; }
	}
	finally { Pop-Location; }
}

#endregion

#region ----- PUBLISHING -----

Task "Generate-Packages" -alias "pack" -description "This task generates the app delployment packages." `
-depends @("restore") -action {
	if (Test-Path $ArtifactsDir) { Remove-Item $ArtifactsDir -Recurse -Force; }
	New-Item $ArtifactsDir -ItemType Directory | Out-Null;
	
	$proj = Get-Item "$RootDir\src\*\*.csproj";
	Write-LineBreak "dotnet: pack '$($proj.BaseName)'";
	$version = Get-BuildboxManifest $ManifestJson | Get-VersionNumber $Branch;
	Exec { &dotnet pack $proj.FullName --output $ArtifactsDir --configuration $Configuration /p:PackageVersion=$version; }
}

Task "Publish-Application" -alias "publish" -description "This task publish all app packages to their respective host." `
-depends @("pack", "push-nuget");

Task "Publish-NuGetPackages" -alias "push-nuget" -description "This task publish all nuget packages to nuget.org." `
-depends @("restore") -action {
	$apiKey = Get-Secret "nugetKey";
	Assert (-not [string]::IsNullOrEmpty($apiKey)) "Your nuget api key was not specified. Provided a value via the `$Secrets parameter eg. `$Secrets=@{'nugetKey'='your_api_key'}";
	Assert (Test-Path $ArtifactsDir) "No nuget packages were found. Try running the 'pack' task then try again.";

	foreach ($nupkg in (Get-ChildItem $ArtifactsDir -Recurse -Filter "*.nupkg"))
	{
		Write-LineBreak "dotnet: nuget push '$($nupkg.Name)'";
		Exec { &dotnet nuget push $nupkg.FullName --source "https://api.nuget.org/v3/index.json" --api-key $apiKey; }
	}
}

#endregion

#region ----- FUNCTIONS -----

function Get-Manifest()
{
	return Get-Content $ManifestJson | Out-String | ConvertFrom-Json;
}

function Get-Secret([string]$key)
{
	$value = $Secrets.$key;
	if ([string]::IsNullOrEmpty($value))
	{
		$value = Get-Content $SecretsJson | Out-String | ConvertFrom-Json | Select-Object -ExpandProperty $key;
	}
	return $value;
}

#endregion

$seperator = "----------------------------------------------------------------------";
FormatTaskName "$seperator`r`n  {0}`r`n$seperator";