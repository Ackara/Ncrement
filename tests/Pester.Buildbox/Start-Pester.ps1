<#
.SYSNOPSIS
This script runs pester tests
#>

Param(
	[Alias('t')]
	[Parameter(ValueFromPipeline)]
	[string]$TestName = ""
)

Get-Item "$(Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)\tools\Pester\*\*.psd1" | Import-Module -Force;
foreach ($testScript in (Get-ChildItem "$PSScriptRoot\Tests" -Filter "*$TestName*.tests.ps1"))
{
	Invoke-Pester -Script $testScript.FullName;
}
