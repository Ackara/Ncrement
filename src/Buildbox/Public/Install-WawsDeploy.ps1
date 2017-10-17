function Install-WAWSDeploy()
{
	<#
	.SYNOPSIS
	Install the wawsdeploy command-line tool from 'https://chocolatey.org/' to the specified directory.

	.DESCRIPTION
	This function will install the wawsdeploy command-line tool from 'https://chocolatey.org/' to the specified directory. Returns the full path of the WAWSDeploy executable.

	.PARAMETER InstallationDirectory
	The installation folder.

	.PARAMETER Version
	The version number. (default: 1.8.0).

	.EXAMPLE
	Install-WawsDeploy "C:\temp";
	In this example, the wawsdeploy cli is downloaded into a temp directory.

	.EXAMPLE
	Install-WawsDeploy;
	In this example, the wawsdeploy cli is downloaded into the current directory.

	.LINK
	https://chocolatey.org/packages/WAWSDeploy
	
	.LINK
	https://github.com/davidebbo/WAWSDeploy
	#>

	Param(
		[Alias("path", "dir", "p")]
		[Parameter(ValueFromPipeline)]
		[string]$InstallationDirectory = "$PSScriptRoot\bin",

		[Alias("ver", "v")]
		[string]$Version = "1.8.0"
	)

	$waws = Get-ChildItem $InstallationDirectory -Recurse -Filter "*WAWSDeploy.exe" | Select-Object -ExpandProperty FullName -First 1;
	if ([String]::IsNullOrEmpty($waws) -or (-not (Test-Path $waws -PathType Leaf)))
	{
		$nupkg = "$InstallationDirectory\wawsdeploy.zip";
		try
		{
			$wawsDir = "$InstallationDirectory\WAWSDeploy\$Version";
			if (-not (Test-Path $InstallationDirectory -PathType Container)) { New-Item $wawsDir -ItemType Directory | Out-Null; }
			if (-not (Test-Path $nupkg -PathType Leaf)) { Invoke-WebRequest "https://chocolatey.org/api/v2/package/WAWSDeploy/$Version" -OutFile $nupkg; }

			Expand-Archive $nupkg -DestinationPath $wawsDir;
			Get-ChildItem "$wawsDir\tools" | Move-Item -Destination $wawsDir;
			Get-ChildItem $wawsDir -Recurse -Exclude @("WAWSDeploy.exe*", "Args.dll") | Remove-Item -Recurse -Force;
			$waws = Get-ChildItem $InstallationDirectory -Recurse -Filter "WAWSDeploy.exe" | Select-Object -ExpandProperty FullName -First 1;
		}
		finally
		{
			if (Test-Path $nupkg -PathType Leaf) { Remove-Item $nupkg; }
		}
	}

	return $waws;
}