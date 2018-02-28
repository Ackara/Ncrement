<#
.SYNOPSIS
This script is meant to be invoke by my MSBuild target. It will update the current project file.
#>

Param(
	[string]$ManifestPath,
	[string]$ProjectFilePath,

	$Major,
	$Minor,
	$Patch,
	$UseDate = "False"
)

$projectDir = $ProjectFilePath;
if (Test-Path $projectDir -PathType Leaf) { $projectDir = Split-Path $projectDir -Parent; }
Get-Item "$PSScriptRoot\*.psd1" | Import-Module;

$manifest = Get-NcrementManifest $ManifestPath;
$vPrev = $manifest | Convert-NcrementVersionNumberToString;


[bool]$withDate = $false;
[bool]::TryParse($UseDate, [ref]$withDate);
if (-not $withDate)
{ 
	$Major = ([Convert]::ToBoolean($Major));
	$Minor = ([Convert]::ToBoolean($Minor));
	$result = $manifest | Step-NcrementVersionNumber -Major:$Major -Minor:$Minor -Patch |  Update-NcrementProjectFile $projectDir;
}
else { $result = $manifest | Step-NcrementVersionNumberUsingDate $Major $Minor $Patch |  Update-NcrementProjectFile $projectDir; }

$vNext = $result.Manifest| Convert-NcrementVersionNumberToString;
Write-Host "Ncrement -> Incremented $([IO.Path]::GetFileNameWithoutExtension($ProjectFilePath)) version from '$vPrev' to '$vNext'.";