<#
.SYNOPSIS
Psake build tasks.
#>

Properties {
	$Manifest = Get-Content "$PSScriptRoot\manifest.json" | Out-String | ConvertFrom-Json;

	# Paths
	$RootDir = (Split-Path $PSScriptRoot -Parent);
	$ArtifactsDir = "$RootDir\artifacts";

	# Args
	$Secrets = @{};
	$TestName = "";
	$Major = $false;
	$Minor = $false;
	$BranchName = "";
	$Commit = $false;
	$BuildConfiguration = "";
	$SkipCompilation = $false;
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
	Write-Host $Secrets;
	if ($Secrets.Count -gt 0)
	{
		$json = "";
		foreach ($arg in $Secrets.GetEnumerator())
		{
			$json += "`"$($arg.Key.Trim())`": `"$($arg.Value.Trim())`",";
		}

		"{$($json.Trim(','))}" | Out-File "$PSScriptRoot\secrets.json" -Encoding utf8;
	}
}

Task "Build-Solution" -alias "compile" -description "This task compile the solution." `
-precondition { return (-not $SkipCompilation); } -depends @("init") -action {
	Assert ("Debug", "Release" -contains $BuildConfiguration) "`$BuildConfiguration was '$BuildConfiguration' but expected 'Debug' or 'Release'.";

	$sln = Get-Item "$RootDir\*.sln" | Select-Object -ExpandProperty FullName;
	$latestVS = (Get-VSSetupInstance | Select-VSSetupInstance -Latest).InstallationPath;
	$msbuild = Get-ChildItem "$latestVS\MSBuild\*\Bin" -Recurse -Filter "MSBuild.exe" | Sort-Object $_.Name | Select-Object -Last 1;

	Write-Breakline "MSBUILD";
	Exec { & $msbuild $sln "/p:Configuration=$BuildConfiguration;Platform=Any CPU" "/v:minimal"; };
	Write-BreakLine;
}

Task "Invoke-Pester" -alias "pester" -description "This task invoke pester test(s)." `
-depends @("init", "compile") -action {
	Write-BreakLine "PESTER";
	foreach ($testScript in (Get-ChildItem "$RootDir\tests\Pester.Buildbox\Tests" -Filter "*$TestName*.tests.ps1"))
	{
		Invoke-Pester -Script $testScript.FullName;
	}
}

Task "Run-VSTests" -alias "vstest" -description "This task runs all MSTest tests." `
-depends @("init", "compile", "pester") -action {
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
}

Task "Run-Tests" -alias "test" -description "This task runs all unit tests." `
-depends @("pester", "vstest");

Task "Update-ProjectManifest" -alias "version" -description "This task increment the the version number of each project as well as their metatdata." `
-depends @("compile") -action {
    $modifiedFiles = New-Object System.Collections.ArrayList;
	# Update manifest.json version number
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
	$modifiedFiles.Add("$PSScriptRoot\manifest.json") | Out-Null;
	Write-Host "`t* increment project version number to $versionNumber.";

    # Update all .csproj version numbers
	foreach ($proj in (Get-ChildItem "$RootDir\src" -Recurse -Filter "*.csproj"))
	{
		[xml]$doc = Get-Content $proj.FullName;
        $assemblyVersion = $doc.SelectSingleNode('/Project/PropertyGroup/AssemblyVersion');
        $assemblyVersion.InnerText = $versionNumber;
        $doc.Save($proj.FullName);

        $modifiedFiles.Add($proj.FullName) | Out-Null;
	}
	Write-Host "`t* updated $($proj.Name) version number to $versionNumber";
		
    #Update powershell manifest
    $dlls = Get-ChildItem "$RootDir\src\Buildbox\Lib" -Filter "*.dll" | Select-Object -ExpandProperty FullName;
    
	Update-ModuleManifest -Path "$RootDir\src\Buildbox\Buildbox.psd1" `
		-RootModule "Buildbox" `
		-ModuleVersion $versionNumber `
		-DotNetFrameworkVersion "4.5.2" `
		-PowerShellVersion '5.0' `
		-Description $Manifest.description `
		-Author $Manifest.author `
		-ProjectUri $Manifest.url `
		-LicenseUri $Manifest.license `
		-Copyright $Manifest.copyright `
		-IconUri $Manifest.icon `
		-Tags $Manifest.tags.Split(' ') `
        -ReleaseNotes (Get-Content "$RootDir\releaseNotes.txt") `
		-RequiredAssemblies @('.\Lib\Acklann.Buildbox.Versioning.dll') `
		-CmdletsToExport @("*") `
		-FunctionsToExport @("*");
	Write-Host "`t* updated powershell module manifest.";
	Test-ModuleManifest "$RootDir\src\Buildbox\Buildbox.psd1" | Out-Null;
    $modifiedFiles.Add("$RootDir\src\Buildbox\Buildbox.psd1") | Out-Null;

	if ($Commit)
	{
        foreach ($file in $modifiedFiles)
        {
            Exec { & git add "$file"; }
        }
		Exec { & git commit -m"update the version numbers to $versionNumber"; }
		Exec { & git tag "v$versionNumber"; }
	}
}

Task "Create-Package" -alias "pack" -description "This task generates a nuget package for each project." `
-depends @("compile") -action {
	if (Test-Path $ArtifactsDir -PathType Container) { Remove-Item $ArtifactsDir -Recurse -Force; }
	
	$moduleDir = "$ArtifactsDir\Buildbox";
	foreach ($folder in @("Lib", "Private", "Public"))
	{
		New-Item "$moduleDir\$folder" -ItemType Directory | Out-Null;
		Get-ChildItem "$RootDir\src\Buildbox\$folder" | Copy-Item -Destination "$moduleDir\$folder";
	}
	Copy-Item -Path "$RootDir\src\Buildbox\*.ps*1" -Destination $moduleDir -Force;
	Write-Host "`t* created package for powershell gallery.";
}

Task "Publish-Package" -alias "publish" -description "Publish all nuget packages to 'powershell gallery'." `
-depends @("pack") -action {
	$psGalleryKey = (Get-Content "$PSScriptRoot\secrets.json" | Out-String | ConvertFrom-Json).psGalleryKey;
	
	if ((-not [String]::IsNullOrEmpty($psGalleryKey)) -and ($BranchName -eq "master"))
	{
		try
		{
			$moduleManifest = Get-ChildItem $ArtifactsDir -Recurse -Filter "*.psd1" | Select-Object -First 1;
			Push-Location $moduleManifest.DirectoryName;
			if (Test-ModuleManifest $moduleManifest)
			{
				Write-Host "`t* $($moduleManifest.Name) module was validated.";
				Publish-Module -Path $PWD -NuGetApiKey $psGalleryKey;
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
