Param(
	[string]$TestName = "",

	[Alias('s')]
	[switch]$SkipBuild
)

if (-not $SkipBuild)
{
	[string]$proj = Join-Path (Split-Path $PSScriptRoot | Split-Path) "src\*.Powershell\*.Powershell.*proj" | Resolve-Path;
	&dotnet msbuild $proj;
}

Clear-Host;
foreach ($file in (Get-ChildItem $PSScriptRoot -Filter "*.tests.ps1"))
{
	Invoke-Pester -Script $file.FullName -TestName "*$TestName*";
}