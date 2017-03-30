<#
.SYNOPSIS
This script invokes all pester tests.
#>

param(
    [string[]]$SelectedTests
)

$srcDir = Split-Path $PSScriptRoot -Parent;
$pester = (Get-Item "$srcDir\packages\pester.*\tools\Pester.psm1" | Select-Object -Last 1 -ExpandProperty FullName);

if (-not (Test-Path $pester -PathType Leaf))
{
    Write-Error "The pester module is missing.";
}

Import-Module $pester;
try
{
    Push-Location $PSScriptRoot;
    if ($Tests.Length -gt 0) 
    { Invoke-Pester -Script $SelectedTests; }
    else 
    { Invoke-Pester; }    
}
finally
{
    Pop-Location;
    if (Get-Module pester) { Remove-Module pester; }
}