function Install-Flyway()
{
	<#
	.SYNOPSIS
	Installs the flyway command-line tool from 'https://flywaydb.org' to the specified directory.

	.PARAMETER InstallationDirectory
	The installation folder.

	.PARAMETER Version
	The version number. (default: 4.2.0).

	.INPUTS
	[String]

	.OUTPUTS
	[String]

	.EXAMPLE
	Install-Flyway "c:\temp";
	In this example, the flyway cli is downloaded into a temp directory.

	.EXAMPLE
	Install-Flyway "c:\temp";
	In this example, the flyway cli is downloaded into the current directory.

	.LINK
	https://flywaydb.org/documentation/
	#>

	Param(
		[Alias('path', 'dir', 'p')]
		[Parameter(ValueFromPipeline)]
		[string]$InstallationDirectory = "$(Split-Path $PSScriptRoot -Parent)\bin",

		[Alias('v', 'ver')]
		[string]$Version = "4.2.0"
	)

	$flyway = Get-ChildItem $InstallationDirectory -Recurse -Filter "flyway.cmd" | Select-Object -ExpandProperty FullName -First 1;
	if ([String]::IsNullOrEmpty($flyway) -or (-not (Test-Path $flyway -PathType Leaf)))
	{
		$archive = "$InstallationDirectory\flyway.zip";
		try
		{
			if (-not (Test-Path $InstallationDirectory -PathType Container)) { New-Item $InstallationDirectory -ItemType Directory | Out-Null; }
			if (-not (Test-Path $archive -PathType Leaf)) { Invoke-WebRequest "https://repo1.maven.org/maven2/org/flywaydb/flyway-commandline/$Version/flyway-commandline-$Version-windows-x64.zip" -OutFile $archive; }
			Expand-Archive $archive -DestinationPath $InstallationDirectory;
			$flyway = Get-ChildItem $InstallationDirectory -Recurse -Filter "flyway.cmd" | Select-Object -ExpandProperty FullName -First 1;
		}
		finally
		{
			if (Test-Path $archive -PathType Leaf) { Remove-Item $archive -Force; }
		}
	}

	return New-Object PSObject -Property @{
		"fileName"=$flyway;
		"configFile"="$(Split-Path $flyway -Parent)\conf\flyway.conf";
	};
}