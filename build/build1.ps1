<#
.SYNOPSIS
This script bootstraps the psake tasks.
#>

Param(
	[Alias('t')]
	[string[]]$Tasks = @("default"),

	[Alias('c')]
	[ValidateSet("Debug", "Release")]
	[string]$Configuration = "Release",

	[Alias('s', "keys")]
	[hashtable]$Secrets = @{},

	[Alias("sc", "nobuild")]
	[switch]$SkipCompilation,

	[Alias("nuget")]
	[string]$NugetPath = "$PSScriptRoot\tools\NuGet\$NugetVersion\nuget.exe",

	[string]$TaskFile = "$PSScriptRoot\build\*psake*.ps1",
	[string]$NugetVersion = "4.3.0",
	[switch]$Major,
	[switch]$Minor,
	[switch]$Help
)

# Set enviroment variables
$branchName = $env:BUILD_SOURCEBRANCHNAME;
if ([string]::IsNullOrEmpty($branchName))
{
	$match = [Regex]::Match((& git branch), '\*\s*(?<name>\w+)');
	if ($match.Success) { $branchName = $match.Groups["name"].Value; }
}

# Download nuget client
if (-not (Test-Path $NugetPath))
{
    $dir = Split-Path $NugetPath -Parent;
    if (-not (Test-Path $dir)) { New-Item $dir -ItemType Directory | Out-Null; }
    Invoke-WebRequest "https://dist.nuget.org/win-x86-commandline/v$NugetVersion/nuget.exe" -OutFile $NugetPath;
}

# Install and invoke Psake
$module = "$PSScriptRoot\tools\psake\*\*.psd1";
if (-not (Test-Path $module)) { Save-Module "psake" -Path "$PSScriptRoot\tools"; }
Import-Module $module -Force;

if ($Help) { Invoke-psake -buildFile $TaskFile -docs; }
else
{
	Write-Host "User:    $env:USERNAME";
	Write-Host "Machine: $env:COMPUTERNAME";
	Write-Host "Branch:  $branchName";
	Invoke-psake $taskFile -nologo -taskList $Tasks -properties @{
		"Secrets"=$Secrets;
		"Branch"=$branchName;
		"nuget" = $NugetPath;
		"Major"=$Major.IsPresent;
		"Minor"=$Minor.IsPresent;
		"Configuration"=$Configuration;
		"SkipCompilation"=$SkipCompilation.IsPresent;
	}
}