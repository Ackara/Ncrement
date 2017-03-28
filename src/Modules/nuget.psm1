function Install-NuGet()
{
	<#
	.SYSNOPSIS
	This cmdlet downloads the nuget.exe tool to a specified path from nuget.org.

	.PARAMETER Version
    The version of the nuget.exe to download.

	.PARAMETER OutFile
    The path of.

    .PARAMETER Overwrite
    Determines whether 

	.INPUTS
	NONE

	.OUTPUTS
	NONE

	.EXAMPLE
    Install-NuGet
    This cmdlet downloads the latest nuget.exe to the current 

	#>
    
    Params(
        [string]$Version,
        [string]$OutFile,
        [switch]$Overwrite
    )

	if ([String]::IsNullOrWhiteSpace($Version)) { $Version = "latest"; }
    if ([String]::IsNullOrWhiteSpace($OutFile)) { $OutFile = "$PSScriptRoot\bin\nuget\nuget.exe"; }

    if ((Test-Path $OutFile -PathType Leaf))
    {
        if ($Overwrite) { Remove-Item $OutFile -Force; }
        else { return; }
    }

    #
    $parentDir = (Split-Path $OutFile -Parent);
    if (-not (Test-Path $parentDir -PathType Container)) { New-Item $parentDir -ItemType Directory; }

    Invoke-WebRequest "https://dist.nuget.org/win-x86-commandline/$Version/nuget.exe" -OutFile $OutFile;
}