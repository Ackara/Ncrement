# SYNOPSIS: This is a psake task file.
Properties {
	# Constants
	$RootDir = "$(Split-Path $PSScriptRoot -Parent)";
	$ManifestJson = "$PSScriptRoot\manifest.json";
	$SecretsJson = "$PSScriptRoot\secrets.json";
	$Nuget = "$PSScriptRoot\bin\nuget.exe";
	$ArtifactsDir = "$RootDir\artifacts";
	$PoshModulesDir = "";

	# Args
	$TargetFramework = "netstandard2.0";
	$SkipCompilation = $false;
	$Configuration = "";
	$Secrets = @{ };
	$Major = $false;
	$Minor = $false;
	$Branch = "";
}

Task "Default" -depends @("Import-Dependencies", "Build-Solution", "Run-Tests");

Task "Deploy" -alias "push" -description "This task compile, test then publish the application." `
-depends @("restore", "version", "build", "test", "pack", "publish");

#region ----- COMPILATION -----

Task "Import-Dependencies" -alias "restore" -description "This task imports all dependencies." `
-action {
	if (-not (Test-Path $nuget))
	{
		$dir = Split-Path $nuget;
		if (-not (Test-Path $dir -PathType Container)) { New-Item $dir -ItemType Directory | Out-Null; }
		Invoke-WebRequest "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe" -OutFile $nuget;
		Write-Host "   * downloaded nuget.exe";
	}

	#  Importing all required powershell modules.
	foreach ($moduleId in @("Pester"))
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
	$manifest = Get-Manifest;

	if ($Major)
	{
		$manifest.version.major += 1;
		$manifest.version.minor = 0;
		$manifest.version.patch = 0;
	}
	elseif ($Minor)
	{
		$manifest.version.minor += 1;
		$manifest.version.patch = 0;
	}
	else
	{
		$manifest.version.patch += 1;
	}

	$manifest | ConvertTo-Json | Out-File $ManifestJson -Encoding utf8;
	Write-Host "   * updated version to $($manifest.version.major).$($manifest.version.minor).$($manifest.version.patch).";
}

Task "Build-Solution" -alias "build" -description "This task compiles the solution." `
-depends @("restore") -precondition { return (-not $SkipCompilation); } -action {
	$psd1 = Get-Item "$RootDir\src\*\*.psd1" -ErrorAction Stop;
	$projectDir = $psd1.DirectoryName;

	$cmdlets = [System.Collections.ArrayList]::new();
	$functions = [System.Collections.ArrayList]::new();
	$nestedModules = [System.Collections.ArrayList]::new();

	foreach ($file in (Get-ChildItem "$projectDir\Private" -Filter "*.ps1" | Where-Object { -not ($_.Name -ieq "Add-NcrementTypes.ps1") }))
	{
		$nestedModules.Add("Private\$($file.Name)") | Out-Null;
	}

	foreach ($file in (Get-ChildItem "$projectDir\Public"))
	{
		$nestedModules.Add("Public\$($file.Name)") | Out-Null;

		#if ($file.BaseName.StartsWith("Update"))
		#{ $cmdlets.Add($file.BaseName) | Out-Null; }
		#else
		#{ $functions.Add($file.BaseName) | Out-Null; }
		$functions.Add($file.BaseName) | Out-Null;
	}

	$manifest = Get-Manifest;
	$version = "$($manifest.version.major).$($manifest.version.minor).$($manifest.version.patch)";

	Update-ModuleManifest $psd1.FullName `
	-ScriptsToProcess @("Private\Add-NcrementTypes.ps1") `
	-NestedModules $nestedModules `
	-FunctionsToExport $functions `
	-PowerShellVersion "5.0" `
	-ModuleVersion $version `
	-Author $manifest.author `
	-CompanyName $manifest.owner `
	-Description $manifest.description `
	-LicenseUri $manifest.license `
	-ProjectUri $manifest.projectUrl `
	-IconUri $manifest.icon `
	-Copyright $manifest.copyright `
	-Tags ($manifest.tags.Split(' ')) `
	-ReleaseNotes $manifest.releaseNotes;

	Write-Host "   * updated $($psd1.Name).";

	# Build package for integration test
	$projectDir = Get-Item "$RootDir\tests\*integration*\" | Select-Object -ExpandProperty FullName;
	$msbuildDir = Join-Path $projectDir "msbuild";
	if (Test-Path $msbuildDir) { Remove-Item $msbuildDir -Force -Recurse; }

	Copy-Item $psd1.DirectoryName -Destination "$msbuildDir\tools\$TargetFramework" -Force -Recurse;
	Copy-Item "$PSScriptRoot\nuget\*.ps1" -Destination "$msbuildDir\tools\$TargetFramework" -Force;

	New-Item "$msbuildDir\build" -ItemType Directory -ErrorAction Ignore | Out-Null;
	Copy-Item "$PSScriptRoot\nuget\*.targets" -Destination "$msbuildDir\build\msbuild.targets" -Force;
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
		Write-LineBreak "pester";
		$testsFailed = 0;
		foreach ($testFile in (Get-ChildItem "$RootDir\tests\*\" -Recurse -Filter "*.tests.ps1"))
		{
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

	$manifest = Get-Manifest;
	$moduleDir = "$RootDir\src\$($manifest.Title)";
	$packageDir = "$ArtifactsDir\$($manifest.Title)";
	New-Item $packageDir -ItemType Directory | Out-Null;

	# Copying the module to powershell gallery package.
	Copy-Item "$moduleDir" -Destination "$ArtifactsDir" -Recurse -Force;
	Get-ChildItem $packageDir -Attributes a | Where-Object { $_.Extension -notmatch ".ps[a-z]*1" } | Remove-Item -Force -Recurse;
	Get-ChildItem $packageDir | Where-Object { $_.Name -match '(bin|obj)' } | Remove-Item -Force -Recurse;

	# Generating nuget package.
	$props = "targetFramework=$TargetFramework;";
	$props += "version=$($manifest.version.major).$($manifest.version.minor).$($manifest.version.patch);";
	foreach ($token in @("id", "description", "author", "owner", "license", "icon", "copyright", "tags", "title", "projectUrl"))
	{
		$props += "$token=$($manifest.$token);";
	}

	Write-LineBreak "nuget: pack";
	Exec { &$nuget pack "$PSScriptRoot\nuget\package.nuspec"-OutputDirectory $ArtifactsDir -Properties $props; }
}

Task "Publish-Application" -alias "publish" -description "This task publish all app packages to their respective host." `
-depends @("pack", "push-psGallery", "push-nuget");

Task "Publish-NuGetPackages" -alias "push-nuget" -description "This task publish all nuget packages to nuget.org." `
-depends @("restore", "pack") -action {
	$apiKey = Get-Secret "nugetKey";
	Assert (-not [string]::IsNullOrEmpty($apiKey)) "Your nuget api key was not specified. Provided a value via the `$Secrets parameter eg. `$Secrets=@{'nugetKey'='your_api_key'}";
	Assert (Test-Path $ArtifactsDir) "No nuget packages were found. Try running the 'pack' task then try again.";

	foreach ($nupkg in (Get-ChildItem $ArtifactsDir -Recurse -Filter "*.nupkg"))
	{
		Write-LineBreak "nuget: push '$($nupkg.Name)'";
		Exec { &$nuget push $nupkg.FullName -Source "https://api.nuget.org/v3/index.json" -ApiKey $apiKey; }
	}
}

Task "Publish-PowershellGallery" -alias "push-psGallery" -description "" `
-depends @("restore", "pack") -action {
	$apiKey = Get-Secret "psGalleryKey";
	Assert (-not [string]::IsNullOrEmpty($apiKey)) "Your powershellGallery api key was not specified. Provided a value via the `$Secrets parameter eg. `$Secrets=@{'psGalleryKey'='your_api_key'}";
	Assert (Test-Path $ArtifactsDir) "No powershell packages were found. Try running the 'pack' task then try again.";

	foreach ($module in (Get-ChildItem $ArtifactsDir -Recurse -Filter "*.psd1"))
	{
		Write-LineBreak "powershell_get '$($module.Name)'";
		if (Test-ModuleManifest $module.FullName)
		{
			try
			{
				Push-Location $module.DirectoryName;
				$name = Split-Path $PWD -Leaf;
				Publish-Module -Path $PWD -NuGetApiKey $apiKey;
				#Write-Warning "NOT IMPLEMENETD $PWD";
			}
			finally { Pop-Location; }
		}
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

function Write-LineBreak([string]$Title = "", [int]$length = 70)
{
	$line = [string]::Join('', [System.Linq.Enumerable]::Repeat('-', $length));
	if (-not [String]::IsNullOrEmpty($Title))
	{
		$line = $line.Insert(4, " $Title ");
		if ($line.Length -gt $length) { $line = $line.Substring(0, $length); }
	}

	Write-Host ''; Write-Host $line; Write-Host '';
}

#endregion

$seperator = "----------------------------------------------------------------------";
FormatTaskName "$seperator`r`n  {0}`r`n$seperator";