<#
#>

$rootDir = Split-Path $PSScriptRoot -Parent;
$nuget = "$rootDir\tools\bin\nuget\nuget.exe";
$packagesDir = "$rootDir\src\packages";

if (-not (Test-Path $nuget -PathType Leaf))
{
    $parentDir = Split-Path $nuget -Parent;
    if (-not (Test-Path $parentDir -PathType Container)) { New-Item $parentDir -ItemType Directory | Out-Null; }
    Invoke-WebRequest "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe" -OutFile $nuget;
}

Write-Host "installing pester.";
& $nuget install Pester -outputdirectory $packagesDir;
& $nuget install Psake -outputdirectory $packagesDir;

