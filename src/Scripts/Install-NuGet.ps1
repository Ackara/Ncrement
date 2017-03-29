<#
.SYNOPSIS
This cmdlet downloads the nuget CLI tool to a specified path.

.PARAMETER Version
The nuget.exe version number.

.PARAMETER OutFile
The path to save the nuget.exe.

.PARAMETER Overwrite
Determines whether to overwrite the nuget.exe if it already exist.

.INPUTS
NONE

.OUTPUTS
System.String

.EXAMPLE
Install-NuGet
This example downloads the latest nuget.exe to the current directory.

.EXAMPLE
Install-NuGet "4.0.0"  -OutFile "C:\project\tools\nuget.exe"
This example downloads version 4.0 to a specified path.

#>

Param(
	[string]$Version,
	[string]$OutFile,
	[switch]$Overwrite
)

if ([String]::IsNullOrWhiteSpace($Version)) { $Version = "latest"; }
if ([String]::IsNullOrWhiteSpace($OutFile)) { $OutFile = "$PWD\bin\nuget\nuget.exe"; }

if ((Test-Path $OutFile -PathType Leaf))
{
	if ($Overwrite) { Remove-Item $OutFile -Force; }
	else { return; }
}

#
$parentDir = (Split-Path $OutFile -Parent);
if (-not (Test-Path $parentDir -PathType Container)) { New-Item $parentDir -ItemType Directory | Out-Null; }

Invoke-WebRequest "https://dist.nuget.org/win-x86-commandline/$Version/nuget.exe" -OutFile $OutFile;
return $OutFile;
