<#
.SYNOPSIS
Bootstrap build script.
#>

Param(
	[Parameter(Position=1)]
	[string[]]$Tasks = @("setup"),

	[string]$NugetKey = "",

	[Parameter(Position=3)]
	[string]$PowershellGalleryKey = "",

	[string]$BuildConfiguration = "Release",

	[Parameter(Position=2)]
	[string]$TestName = "",

	[string]$ReleaseTag = $null,

	[switch]$Help
)

# Assign Values
$config = "$PSScriptRoot\build\config.json";
if (Test-Path $config -PathType Leaf)
{
	$config = Get-Content "$PSScriptRoot\build\config.json" | Out-String | ConvertFrom-Json;
}

if ($ReleaseTag -eq $null)
{
	$branch = (& git branch);
	if ($branch -notcontains "* master") { $ReleaseTag = "alpha"; }
}

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
if (-not (Test-Path "$PSScriptRoot\tools\psake" -PathType Container))
{
	Save-Module psake -Path "$PSScriptRoot\tools";
}
Get-Item "$PSScriptRoot\tools\psake\*\*.psd1" | Import-Module -Force;

$buildFile = "$PSScriptRoot\build\tasks.ps1";
if ($Help) 
{ Invoke-psake -buildFile $buildFile -detailedDocs; }
else
{
	Invoke-psake -buildFile $buildFile -taskList $Tasks -framework 4.5.2 -nologo -notr `
	-properties @{
		"nuget"=$nuget;
		"Config"=$config;
		"TestName"=$TestName;
		"NugetKey"=$NugetKey;
		"ReleaseTag"=$ReleaseTag;
		"RootDir" = $PSScriptRoot;
		"PsGalleryKey"=$PowershellGalleryKey;
		"BuildConfiguration"=$BuildConfiguration;
	}
	
	if(-not $psake.build_success) { exit 1; }
}