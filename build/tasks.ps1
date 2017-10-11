<#
.SYNOPSIS
Psake build tasks.
#>

Properties {
	$Manifest = Get-Content "$PSScriptRoot\manifest.json" | Out-String | ConvertFrom-Json;

	# Paths
	$RootDir = (Split-Path $PSScriptRoot -Parent);
	$ArtifactsDir = "$RootDir\artifacts";

	# Deployment Args
	$Secrets = @{};
	$Major = $false;
	$Minor = $false;
	$BranchName = "";
	$BuildConfiguration = "";
}

# -----

Task "Load-Dependencies" -alias "init" -description "This task load all dependencies." -action {
	foreach ($moduleName in @("Pester", "VSSetup"))
	{
		if (-not (Test-Path "$RootDir\tools\$moduleName" -PathType Container))
		{
			Save-Module $moduleName -Path "$RootDir\tools";
		}

		$module = Get-Item "$RootDir\tools\$moduleName\*\*" -Filter "*.psd1" | Import-Module -Force -PassThru;
		Write-Host "`t* imported $module module.";
	}

	foreach ($psm1 in (Get-ChildItem "$RootDir\build" -Filter "*.psm1" | Select-Object -ExpandProperty FullName))
	{
		Import-Module $psm1 -Force;
		Write-Host "`t* imported $(Split-Path $psm1 -Leaf) module.";
	}

	if ($Secrets.Count -gt 0)
	{
		$keyValuePairs = "";
		foreach ($pair in $Secrets.GetEnumerator())
		{
			$keyValuePairs += "'$($pair.Key)': '$($pair.Value)',";
		}

		"{$($keyValuePairs.Trim(','))}" | Out-File "$PSScriptRoot\secrets.json" -Encoding utf8;
	}
}

Task "Build-Solution" -alias "compile" -description "This task compile the solution." `
-depends @("init") -action {
	Assert ("Debug", "Release" -contains $BuildConfiguration) "`$BuildConfiguration was '$BuildConfiguration' but expected 'Debug' or 'Release'.";

	$sln = Get-Item "$RootDir\*.sln" | Select-Object -ExpandProperty FullName;
	$latestVS = (Get-VSSetupInstance | Select-VSSetupInstance -Latest).InstallationPath;
	$msbuild = Get-ChildItem "$latestVS\MSBuild\*\Bin" -Recurse -Filter "MSBuild.exe" | Sort-Object $_.Name | Select-Object -Last 1;

	Write-Breakline "MSBUILD";
	Exec { & $msbuild $sln "/p:Configuration=$BuildConfiguration;Platform=Any CPU"  "/v:minimal"; };
	Write-BreakLine;
}

Task "Run-Tests" -alias "test" -description "This task runs all unit tests." `
-depends @("compile") -action {
	$totalFailedTests = 0;

	Write-BreakLine "VSTEST";
	foreach ($proj in (Get-ChildItem "$RootDir\tests\*\*" -Filter "*.csproj" | Select-Object -ExpandProperty FullName))
	{
		try
		{
			Push-Location (Split-Path $proj -Parent);
			Exec { & dotnet test; }
		}
		finally { Pop-Location; }
	}

    Write-BreakLine "PESTER";
    & "$RootDir\tests\Pester.Buildbox\Start-Pester.ps1";
	Write-BreakLine;
}

Task "Update-ProjectManifest" -alias "version" -description "This task increment the the version number of each project as well as their metatdata." `
-depends @("compile") -action {
	$version = $Manifest.version;
	$version.patch = $version.patch + 1;
	if ($Major) 
	{ 
		$version.major = $version.major + 1;
		$version.minor = 0;
		$version.patch = 0;
	}
	elseif ($Minor) 
	{ 
		$version.minor = $version.minor + 1; 
		$version.patch = 0;
	}
	$versionNumber = "$($version.major).$($version.minor).$($version.patch)";
    $Manifest | ConvertTo-Json | Out-File "$PSScriptRoot\manifest.json" -Encoding utf8;
	Exec { & git add "$PSScriptRoot\manifest.json"; }
	Write-Host "`t* increment project version number to $versionNumber.";

	foreach ($proj in (Get-ChildItem "$RootDir\src" -Recurse -Filter "*.csproj"))
	{
		$assemblyInfo = Get-Item "$($proj.DirectoryName)\Properties\AssemblyInfo.cs";
		$content = Get-Content $assemblyInfo | Out-String;
		$content = $content -replace '"(\d\.?)+"', "`"$versionNumber`"";
		$content.Trim() | Out-File $assemblyInfo -Encoding utf8;
		Exec { & git add "$assemblyInfo"; }
	}
	Write-Host "`t* updated $($proj.Name) version number to $versionNumber";
		
	Update-ModuleManifest -Path "$RootDir\src\Buildbox\Buildbox.psd1" `
		-RootModule "Buildbox" `
		-ModuleVersion $versionNumber `
		-DotNetFrameworkVersion "4.5.2" `
		-PowerShellVersion '5.0' `
		-Author $Manifest.author `
		-ProjectUri $Manifest.url `
		-LicenseUri $Manifest.license `
		-Copyright $Manifest.copyright `
		-IconUri $Manifest.icon `
		-Tags $Manifest.tags.Split(' ') `
		-RequiredAssemblies @("lib\Acklann.Buildbox.SemVer.dll") `
		-CmdletsToExport @("*") `
		-FunctionsToExport @("*");
	Write-Host "`t* updated powershell module manifest.";
	Test-ModuleManifest "$RootDir\src\Buildbox\Buildbox.psd1";

	Exec { & git add "$RootDir\src\Buildbox\Buildbox.psd1"; }
	Exec { & git commit -m"update the version numbers to $versionNumber"; }
	Exec { & git tag "v$versionNumber"; }
}

Task "Create-Package" -alias "pack" -description "This task generates a nuget package for each project." `
-depends @("compile") -action {
	if (Test-Path $ArtifactsDir -PathType Container) { Remove-Item $ArtifactsDir -Recurse -Force; }
	
	foreach ($folder in @("lib", "Private", "Public"))
	{
		New-Item "$ArtifactsDir\$folder" -ItemType Directory | Out-Null;
		Get-ChildItem "$RootDir\src\Buildbox\$folder" | Copy-Item -Destination "$ArtifactsDir\$folder";
	}
	Copy-Item -Path "$RootDir\src\Buildbox\*.ps*1" -Destination $ArtifactsDir -Force;
	Write-Host "`t* created package for powershell gallery.";
}

Task "Publish-Package" -alias "publish" -description "Publish all nuget packages to 'powershell gallery'." `
-depends @("pack") -action {
	$secrets = Get-Content "$PSScriptRoot\secrets.json" | Out-String | ConvertFrom-Json;
	$psGalleryKey = $secrets.psGalleryKey;
	
	if ((-not [String]::IsNullOrEmpty($psGalleryKey)) -and ($BranchName -eq "master"))
	{
		try
		{
			$moduleManifest = Get-Item "$ArtifactsDir\Buildbox.psd1";
			Push-Location $moduleManifest.DirectoryName;
			if (Test-ModuleManifest $moduleManifest)
			{
				Publish-Module -Path $moduleManifest.DirectoryName -NuGetApiKey $psGalleryKey -WhatIf;
			}
		}
		finally { Pop-Location; }
	}
	else 
	{ 
		Write-Host "branch: '$BranchName'" -ForegroundColor DarkYellow;
		Write-Host "PSGalleryKey: '$psGalleryKey'" -ForegroundColor DarkYellow;
		Write-Warning "publishing cancelled because you are not on the master branch or the ps gallery key was not supplied.";
	}
}