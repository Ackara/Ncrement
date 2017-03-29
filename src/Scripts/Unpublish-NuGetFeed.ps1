<#
.SYNOPSIS
Removes a package feed from a package source.

.DESCRIPTION
This cmdlet delete/unlist an entire feed from a package source. The nuget 'delete' command only unlist a specific version of package. This command will enumerate the entire feed and invoke the 'delete' on each package.

.PARAMETER PackageId
The name of the feed to remove.

.PARAMETER ApiKey
The API key for the target repository. If not present, the one specified in %AppData%\NuGet\NuGet.Config is used.

.PARAMETER Source
The nuget server url.

.PARAMETER Nuget
The path to an existing nuget.exe.

.INPUTS
System.String

.OUTPUTS
NONE

.EXAMPLE
.\Unpublish-NugetFeed.ps1 "yourpackage" "your_aip_key";
This example removes a feed from nuget.org.

.EXAMPLE
.\Unpublish-NugetFeed.ps1 -PackageId "yourpackage" -ApiKey "your_aip_key" -Source "http:\\myprivatefeed.com\nuget\v1";
This example removes a feed from a private package source.

#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = "High")]
param(
    [Parameter()]
    [string]$PackageId,
    
    [Parameter()]
    [string]$ApiKey,
    
    [Parameter()]
    [string]$Source = "https://api.nuget.org/v3/index.json",

    [string]$Nuget
)


if ([String]::IsNullOrWhiteSpace($Nuget)) { $Nuget = "$PSScriptRoot\bin\nuget\nuget.exe"; }

if (-not (Test-Path $Nuget -PathType Leaf))
{
    $parentDir = Split-Path $Nuget -Parent;
    if (-not (Test-Path $parentDir -PathType Container)) { New-Item $parentDir -ItemType Directory | Out-Null; }
    Invoke-WebRequest "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe" -OutFile $Nuget;
}

$currentPackage;
$previousPackage;
$morePackagesExists = $true;

do
{
    [string]$currentPackage = (& $Nuget list "$PackageId");

    if (($currentPackage -ine $previousPackage) -and (-not [String]::IsNullOrEmpty($currentPackage)))
    {
        $parts = $currentPackage.Split(' ');
        $package = $parts[0].Trim();
        $version = $parts[1].Trim();

        $output = (& $nuget delete $package $version -source $Source -apikey $ApiKey -noninteractive);
        Write-Host "exit($LASTEXITCODE): $package $version was deleted successfully.";
        $previousPackage = $currentPackage;
    }
    elseif ($currentPackage -eq $previousPackage)
    {
        Write-Host "Waiting for '$currentPackage' to be unlisted ...";
        Start-Sleep -Seconds 10;
    }
    else
    { $morePackagesExists = $false; }
    
} while ($morePackagesExists)

