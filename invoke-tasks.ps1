<#
.SYNOPSIS
Bootstrap build script.
#>

Param(
	[Parameter(Position=2)]
	[string]$NugetKey = "",

	[Parameter(Position=3)]
	[string]$PowershellGalleryKey = "",

	[string]$BuildConfiguration = "Release",

	[Parameter(Position=1)]
	[string[]]$Tasks = @("setup"),

	[string]$TestName = "",

	[switch]$Help
)

# Assign Values
$config = Get-Content "$PSScriptRoot\build\config.json" | Out-String | ConvertFrom-Json;

if ([String]::IsNullOrEmpty($NugetKey)) { $NugetKey = $config.nuget.apiKey; }
if ([String]::IsNullOrEmpty($PowershellGalleryKey)) { $PowershellGalleryKey = $config.powershellGallery.apiKey; }
$branch = ((& git branch)[0].Trim('*', ' '));
$releaseTag = "";
if ($branch -ne "master")
{ $releaseTag = "alpha"; }

# Restore Packages
$nuget = "$PSScriptRoot\tools\nuget.exe";
if (-not (Test-Path $nuget -PathType Leaf))
{
	$parentDir = Split-Path $nuget -Parent;
	if (-not (Test-Path $parentDir -PathType Container)) { New-Item $parentDir -ItemType Directory | Out-Null; }
	Invoke-WebRequest "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe" -OutFile $nuget;
}

& $nuget restore "$PSScriptRoot\Buildbox.sln" -Verbosity quiet;

# Invoke Psake
$psake = Get-Item "$PSScriptRoot\packages\psake.*\tools\psake.psm1" | Sort-Object { $_.Name } | Select-Object -Last 1;
Import-Module $psake -Force;

$buildFile = "$PSScriptRoot\build\tasks.ps1";
if ($Help) 
{ Invoke-psake -buildFile $buildFile -detailedDocs; }
else
{
	Invoke-psake -buildFile $buildFile -taskList $Tasks -framework 4.5.2 -nologo -notr `
	-properties @{
		"TestName"=$TestName;
		"nuget"=$nuget;
		"Config"=$config;
		"Branch"=$branch;
		"NugetKey"=$NugetKey;
		"ReleaseTag"=$releaseTag;
		"PsGalleryKey"=$PowershellGalleryKey;
		"BuildConfiguration"=$BuildConfiguration;
	}
}