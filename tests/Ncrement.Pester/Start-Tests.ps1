Param(
	[string]$TestName = ""
)

foreach ($file in (Get-ChildItem $PSScriptRoot -Filter "*$TestName*.tests.ps1"))
{
	Invoke-Pester -Script $file.FullName;
}