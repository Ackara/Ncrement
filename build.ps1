<#
.SYNOPSIS
Run one or more tasks defined in the '\build\tasks.psake.ps1' file.

.EXAMPLE
.\build.ps1 -Help;
This example prints a list of all the available tasks.
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
	
	[string]$TaskFile = "$PSScriptRoot\build\*psake*.ps1",
	[switch]$Major,
	[switch]$Minor,
	[switch]$Help
)

# Get source control branch name.
$branchName = $env:BUILD_SOURCEBRANCHNAME;
if ([string]::IsNullOrEmpty($branchName))
{
	$match = [Regex]::Match((& git branch), '\*\s*(?<name>\w+)');
	if ($match.Success) { $branchName = $match.Groups["name"].Value; }
}

# Install then invoke Psake tasks.
$psModulesDir = "$PSScriptRoot\build\powershell_modules";
$modulePath = "$psModulesDir\psake\*\*.psd1";
if (-not (Test-Path $modulePath))
{ 
	if (-not (Test-Path $psModulesDir)) { New-Item $psModulesDir -ItemType Directory | Out-Null; }
	Save-Module "psake" -Path $psModulesDir; 
}
Import-Module $modulePath -Force;

if ($Help) { Invoke-Psake -buildFile $TaskFile -docs; }
else
{
	Write-Host -ForegroundColor DarkGray "User:     $env:USERNAME";
	Write-Host -ForegroundColor DarkGray "Machine:  $env:COMPUTERNAME";
	Write-Host -ForegroundColor DarkGray "Platform: $env:OS";
	Write-Host -ForegroundColor DarkGray "Branch:   $branchName";
	Invoke-psake $taskFile -nologo -taskList $Tasks -properties @{
		"Secrets"=$Secrets;
		"Branch"=$branchName;
		"Major"=$Major.IsPresent;
		"Minor"=$Minor.IsPresent;
		"PoshModulesDir"=$psModulesDir;
		"Configuration"=$Configuration;
		"SkipCompilation"=$SkipCompilation.IsPresent;
	}
	if (-not $psake.build_success) { exit 1; }
}