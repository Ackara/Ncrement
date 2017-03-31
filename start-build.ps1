<#
.SYNOPSIS
Bootstrap build script
#>

Param(
    

    [Parameter(Position=1)]
    [string[]]$Tasks = @("setup"),

    [switch]$Help
)

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
    Invoke-psake -buildFile $buildFile -taskList $Tasks -nologo -notr `
    -properties @{
        "nuget"=$nuget;
    }
}