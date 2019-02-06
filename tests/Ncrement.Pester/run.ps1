Param(
	[string]$TestName = ""
)

Clear-Host;
foreach ($file in (Get-ChildItem $PSScriptRoot -Filter "*.tests.ps1"))
{
	Invoke-Pester -Script $file.FullName -TestName "*$TestName*";
}