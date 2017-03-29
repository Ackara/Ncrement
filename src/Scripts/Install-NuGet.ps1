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
Install-NuGet "4.0.0" -OutFile "C:\project\tools\nuget.exe"
This example downloads version 4.0 to a specified path.

#>

[CmdletBinding()]
Param(
	[string]$Version,
	[string]$OutFile,
	[switch]$Overwrite
)

if ([String]::IsNullOrWhiteSpace($OutFile)) { $OutFile = "$PWD\bin\nuget\nuget.exe"; }

if ([String]::IsNullOrWhiteSpace($Version)) 
{ $Version = "latest"; }
else 
{ $Version = "v$Version"; }

if ((Test-Path $OutFile -PathType Leaf))
{
	if ($Overwrite)
	{
		Write-Verbose "overwritten existing nuget.exe";
		Remove-Item $OutFile -Force;
	}
	else
	{
		Write-Verbose "nuget.exe already exist";
		return;
	}
}

$parentDir = (Split-Path $OutFile -Parent);
if (-not (Test-Path $parentDir -PathType Container)) { New-Item $parentDir -ItemType Directory | Out-Null; }

Write-Verbose "downloading nuget.exe from nuget.org ...";
Invoke-WebRequest "https://dist.nuget.org/win-x86-commandline/$Version/nuget.exe" -OutFile $OutFile;
return $OutFile;