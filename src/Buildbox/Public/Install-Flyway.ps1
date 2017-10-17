function Install-Flyway()
{
	<#
	.SYNOPSIS
	Install the flyway command-line tool from 'https://flywaydb.org' to the specified directory.

	.DESCRIPTION
	This function will install the flyway command-line tool from 'https://flywaydb.org' to the specified directory. Returns a PSCustomObject the stores the full path of the flyway executable ([string] Filename) and its configuration file ([string] ConfigFile).

	.PARAMETER InstallationDirectory
	The installation folder.

	.PARAMETER Version
	The version number. (default: 4.2.0).
	
	.OUTPUTS
	System.Management.Automation.PSCustomObject

	.EXAMPLE
	Install-Flyway "c:\temp";
	In this example, the flyway cli is downloaded into a temp directory.

	.EXAMPLE
	$flyway = Install-Flyway "c:\temp";
	In this example, the flyway cli is downloaded into the current directory.

	.LINK
	https://flywaydb.org/documentation/
	#>

	Param(
		[Alias('p', 'dir', 'path')]
		[Parameter(ValueFromPipeline)]
		[string]$InstallationDirectory = "$(Split-Path $PSScriptRoot -Parent)\bin",

		[Alias('v', 'ver')]
		[string]$Version = "4.2.0"
	)

	$flyway = Get-ChildItem $InstallationDirectory -Recurse -Filter "flyway.cmd" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName -First 1;
	if ([String]::IsNullOrEmpty($flyway) -or (-not (Test-Path $flyway -PathType Leaf)))
	{
		# Download the flyway CLI
		$archive = "$InstallationDirectory\flyway.zip";
		try
		{
			if (-not (Test-Path $InstallationDirectory -PathType Container)) { New-Item $InstallationDirectory -ItemType Directory | Out-Null; }
			if (-not (Test-Path $archive -PathType Leaf)) { Invoke-WebRequest "https://repo1.maven.org/maven2/org/flywaydb/flyway-commandline/$Version/flyway-commandline-$Version-windows-x64.zip" -OutFile $archive; }
			Expand-Archive $archive -DestinationPath $InstallationDirectory;
			$newDir = "$InstallationDirectory\flyway";
			if (-not (Test-Path $newDir -PathType Container)) { New-Item $newDir -ItemType Directory | Out-Null; }
			Move-Item "$InstallationDirectory\flyway-$Version" -Destination $newDir;
			Rename-Item "$newDir\flyway-$Version" -NewName $Version;
			$flyway = Get-ChildItem $InstallationDirectory -Recurse -Filter "flyway.cmd" | Select-Object -ExpandProperty FullName -First 1;
		}
		finally
		{
			if (Test-Path $archive -PathType Leaf) { Remove-Item $archive -Force; }
		}
	}

	return New-Object PSCustomObject -Property @{
		"FileName"=$flyway;
		"ConfigFile"="$(Split-Path $flyway -Parent)\conf\flyway.conf";
	};
}