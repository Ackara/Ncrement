# SYNOPSIS: This is a psake task file.
Properties {
	# Constants
	$RootDir = "$(Split-Path $PSScriptRoot -Parent)";
	$SecretsJson = "$PSScriptRoot\secrets.json";
	$Nuget = "$PSScriptRoot\bin\nuget.exe";
	$ArtifactsDir = "$RootDir\artifacts";
	$ToolsDir = "";

	# Args
	$TargetFramework = "netstandard2.0";
	$SkipCompilation = $false;
	$Configuration = "";
	$Secrets = @{ };
	$Major = $false;
	$Minor = $false;
	$Debug = $false;
	$Branch = "";
}

Task "Default" -depends @("restore", "build", "test", "pack");

Task "Deploy" -alias "push" -description "This task compile, test then publish the application." `
-depends @("restore", "version", "test", "pack", "push-ps");

#region ----- COMPILATION -----

Task "Import-Dependencies" -alias "restore" -description "This task imports all dependencies." `
-action {
	#  Importing all required powershell modules.
	foreach ($moduleId in @("Pester"))
	{
		$modulePath = Join-Path $ToolsDir "$moduleId/*/*.psd1";
		if (-not (Test-Path $modulePath)) { Save-Module $moduleId -Path $ToolsDir; }
		Write-Host "  -> imported $moduleId.";
	}

	# Add secrets.json if not exist.
	$secretsPath = Join-Path $PSScriptRoot "secrets.json";
	if (-not (Test-Path $secretsPath))
	{
		'{ "psGalleryKey": null }' | Out-File -FilePath $secretsPath -Encoding utf8;
		Write-Host "  -> created secrets.json";
	}
}

Task "Increment-VersionNumber" -alias "version" -description "This task increments the project's version numbers." `
-depends @("restore") -action {
	[string]$manifestPath = Join-Path $PSScriptRoot "manifest.json" | Resolve-Path;
	$manifest = Get-Content $manifestPath | ConvertFrom-Json;
	$oldVersion =  "$($manifest.version.major).$($manifest.version.minor).$($manifest.version.patch)";

	if ($Major)
	{
		$manifest.version.major++;
		$manifest.version.minor = 0;
		$manifest.version.patch = 0;
	}
	elseif ($Minor)
	{
		$manifest.version.minor++;
		$manifest.patch = 0;
	}
	else { $manifest.version.patch++; }
	$version =  "$($manifest.version.major).$($manifest.version.minor).$($manifest.version.patch)";

	$manifest | ConvertTo-Json | Out-File $manifestPath -Encoding utf8;
	Invoke-Build;
	[string]$psd1 = Join-Path $RootDir "src/*/*.psd1" | Resolve-Path;
	&git add $psd1; &git add $manifestPath;
	&git commit -m "Update version-number to $version";

	Write-Host "  -> incremented version number from '$oldVersion' to '$version'.";
}

Task "Build-Solution" -alias "build" -description "This task compiles the solution." `
-depends @("restore") -precondition { return (-not $SkipCompilation); } -action { Invoke-Build; }

Task "Run-Tests" -alias "test" -description "This task invoke all tests within the 'tests' folder." `
-depends @("restore") -action {
	try
	{
		# Running all Pester tests.
		Push-Location $RootDir;
		Write-LineBreak "pester";
		$testsFailed = 0;
		foreach ($testFile in (Get-ChildItem "$RootDir\tests\*\" -Recurse -Filter "public.tests.ps1"))
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

	$moduleDir = Join-Path $RootDir "src/*/*.psd1" | Resolve-Path | Split-Path -Parent | Get-Item;
	$packageDir = Join-Path $ArtifactsDir $moduleDir.Name;

	# Copying the module to powershell gallery package.
	Copy-Item $moduleDir -Destination $packageDir -Recurse;
	Get-ChildItem $packageDir -Directory | Where-Object { ($_.Name -eq "bin") -or ($_.Name -eq "obj") } | Remove-Item -Recurse -Force;
	Get-ChildItem $packageDir -Recurse -File | Where-Object { $_.Name -notlike "*.ps*1" } | Remove-Item -Force;
	Write-Host " -> created $($moduleDir.Name) module.";
}

Task "Publish-PowershellGallery" -alias "push-ps" -description "" `
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
			}
			finally { Pop-Location; }
		}
	}
}

#endregion

#region ----- FUNCTIONS -----

function Invoke-Build
{
	$psd1 = Get-Item "$RootDir\src\*\*.psd1" -ErrorAction Stop;
	$projectDir = $psd1.DirectoryName;

	$cmdlets = [System.Collections.ArrayList]::new();
	$functions = [System.Collections.ArrayList]::new();
	$nestedModules = [System.Collections.ArrayList]::new();

	foreach ($file in (Get-ChildItem "$projectDir\Private" -Filter "*.ps1"))
	{
		$nestedModules.Add("Private\$($file.Name)") | Out-Null;
		if ($Debug) { $functions.Add($file.BaseName) | Out-Null; }
	}

	foreach ($file in (Get-ChildItem "$projectDir\Public"))
	{
		$nestedModules.Add("Public\$($file.Name)") | Out-Null;
		$cmdlets.Add($file.BaseName) | Out-Null;
		Write-Host " -> added $($file.BaseName) cmdlet.";
	}

	$manifest = Get-Content (Join-Path $PSScriptRoot "manifest.json") | ConvertFrom-Json;
	if (Test-Path $psd1) { Remove-Item $psd1 | Out-Null; }

	New-ModuleManifest $psd1.FullName `
	-Guid "332b06ed-278e-482a-b17c-98919e43f577" `
	-ModuleVersion "$($manifest.version.major).$($manifest.version.minor).$($manifest.version.patch)" `
	-Description "A module for applying semantic versioning to your projects." `
	-Author "Ackara" `
	-CompanyName "Ackara" `
	-IconUri $manifest.iconUri `
	-ProjectUri $manifest.projectUri `
	-LicenseUri $manifest.licenseUri `
	-ReleaseNotes $manifest.releaseNotes `
	-Tags @("semantic", "version", "build", "automation", ".net") `
	-Copyright "Copyright (c) $(Get-Date | Select-Object -ExpandProperty Year) Ackara" `
	-NestedModules $nestedModules `
	-CmdletsToExport $cmdlets `
	-PowerShellVersion "5.0";

	Write-Host " -> updated $($psd1.Name).";
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