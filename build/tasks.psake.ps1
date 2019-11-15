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

Task "Default" -alias "build" -depends @("restore", "compile", "test", "pack");

Task "Publish" -alias "push" -description "This task compile, test then publish the application." `
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
	[string]$psd1 = Join-Path $RootDir "src/*/*.psd1" | Resolve-Path;

	Update-ModuleManifest $psd1 -ModuleVersion $version `
	-Author $manifest.author `
	-CompanyName $manifest.company `
	-Description $manifest.description `
	-IconUri $manifest.iconUri `
	-ProjectUri $manifest.projectUri `
	-LicenseUri $manifest.licenseUri `
	-ReleaseNotes $manifest.releaseNotes `
	-Tags @("semantic", "version", "build", "automation", ".net");

	Write-Host "  -> incremented version number from '$oldVersion' to '$version'.";
}

Task "Build-Solution" -alias "compile" -description "This task compiles the solution." `
-depends @("restore") -precondition { return (-not $SkipCompilation); } -action {
	[string]$sln = Join-Path $RootDir "*.sln" | Resolve-Path;
	&dotnet build $sln --configuration $Configuration;
}

Task "Run-Tests" -alias "test" -description "This task invoke all tests within the 'tests' folder." `
-depends @("restore") -action {
	try
	{
		Push-Location $RootDir;

		# Running all mstest
		Write-LineBreak "MSTest";
		[string]$proj = Join-Path $RootDir "tests/*.MSTest/*.proj" | Resolve-Path;
		&dotnet test $proj;

		# Running all Pester tests.
		Write-LineBreak "pester";
		$testsFailed = 0;
		foreach ($testFile in (Get-ChildItem "$RootDir\tests\*.Pester\*.tests.ps1" -Recurse))
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
	# Generating the cmdlets xml help file
	$nupkg = Join-Path ([IO.Path]::GetTempPath()) "xmldoc2cmdletdoc.zip";
	if (-not (Test-Path $nupkg))
	{
		Invoke-WebRequest "https://www.nuget.org/api/v2/package/XmlDoc2CmdletDoc/0.2.13" -OutFile $nupkg;
	}

	$x2cDir = Join-Path $ToolsDir "XmlDoc2CmdletDoc";
	$xmlDoc2CmdletDoc = Join-Path $x2cDir "tools/XmlDoc2CmdletDoc.exe";
	if (-not (Test-Path $xmlDoc2CmdletDoc))
	{
		Expand-Archive $nupkg -DestinationPath $x2cDir -Force;
	}

	[string]$dll = Join-Path $ArtifactsDir "*/*.Powershell.dll" | Resolve-Path;
	&$xmlDoc2CmdletDoc $dll;
	[string]$help = Join-Path $ArtifactsDir "*/*-Help.xml" | Resolve-Path;
	$help | Copy-Item -Destination (Join-Path (Split-Path $help -Parent) "$(Split-Path $RootDir -Leaf)-Help.xml") -Force;

	# -----

	[string]$proj = Join-Path $RootDir "src/*.CodeGen/*.csproj" | Resolve-Path;
	&dotnet publish $proj --configuration $Configuration;

	$dll = Join-Path (Split-Path $proj -Parent) "bin/$Configuration/*/publish/*.CodeGen.dll" | Resolve-Path;
	$schema = Join-Path $RootDir "schema.json";
	#&dotnet $dll "$schema";
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