<#
.SYNOPSIS
Psake build tasks.
#>

Properties {
	$Manifest = Get-Content "$PSScriptRoot\manifest.json" | Out-String | ConvertFrom-Json;

	# Paths
	$RootDir = (Split-Path $PSScriptRoot -Parent);
	$ArtifactsDir = "$RootDir\artifacts";

	# Tools
	$nuget = "";

	# Enviroment Args
	$ReleaseTag = "";
	$BuildConfiguration = "";

	# User Args
	$TestName = $null;
	$Config = $null;
	$PsGalleryKey = "";
	$NuGetKey = "";
}

# -----

Task "Init" -description "This task load all dependencies." -action {
	$modules = @("Pester", "VSSetup");
	foreach ($name in $modules)
	{
		if (-not (Test-Path "$RootDir\tools\$name" -PathType Container))
		{
			Save-Module $name -Path "$RootDir\tools";
		}

		$id = Get-Item "$RootDir\tools\$name\*\*" -Filter "*.psd1" | Import-Module -Force -PassThru;
		Write-Host "`t* imported $id module.";
	}

	foreach ($psm1 in (Get-ChildItem "$RootDir\build" -Filter "*.psm1" | Select-Object -ExpandProperty FullName))
	{
		Import-Module $psm1 -Force;
		Write-Host "`t* $(Split-Path $psm1 -Leaf) imported.";
	}
}

Task "Cleanup" -description "This task releases all resources." -action {}

Task "setup" -description "Run this task to help configure your local enviroment for development." `
-depends @("Init") -action {
}

Task "Build-Solution" -alias "compile" -description "This task compile the solution." `
-depends @("Init") -action {
	Assert ("Debug", "Release" -contains $BuildConfiguration) "`$BuildConfiguration was '$BuildConfiguration' but expected 'Debug' or 'Release'.";

	$sln = Get-Item "$RootDir\*.sln" | Select-Object -ExpandProperty FullName;
	$latestVS = (Get-VSSetupInstance | Select-VSSetupInstance -Latest).InstallationPath;
	$msbuild = Get-ChildItem "$latestVS\MSBuild\*\Bin" -Recurse -Filter "MSBuild.exe" | Sort-Object $_.Name | Select-Object -Last 1;

	Write-Breakline "MSBUILD";
	Exec { & $msbuild $sln "/p:Configuration=$BuildConfiguration;Platform=Any CPU"  "/v:minimal"; };
	Write-BreakLine;
}

Task "Run-Pester" -alias "pester" -description "This task invoke all selected pester tests." `
-depends @("Build-Solution") -action {
	$totalFailedTests = 0;
	if ([String]::IsNullOrEmpty($TestName))
	{
		foreach($script in (Get-ChildItem "$RootDir\tests" -Recurse -Filter "*.tests.ps1" | Select-Object -ExpandProperty FullName))
		{
			$results = Invoke-Pester -Script $script -PassThru;
			if ($results.FailedCount -gt 0) { throw "Passed: $($results.PassedCount), Failed: $($results.FailedCount)"; }
		}
	}
	else
	{
		$script = Get-ChildItem "$RootDir\tests" -Recurse -Filter "*$TestName*.ps1" | Select-Object -ExpandProperty FullName -First 1;
		$results = Invoke-Pester -Script $script -PassThru;
		if ($results.FailedCount -gt 0) { throw "Passed: $($results.PassedCount), Failed: $($results.FailedCount)"; }
	}
}

Task "Run-Tests" -alias "test" -description "This task runs all tests." `
-depends @("Build-Solution", "Run-Pester") -action {
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
	Write-BreakLine;
}

Task "Increment-Version" -alias "version" -description "This task increment the the version number of each project." `
-depends @() -action {
	$version = $Manifest.version;
	$version.patch = ([Int]::Parse($version.patch) + 1);
	$value = "$($version.major).$($version.minor).$($version.patch)";
	$Manifest | ConvertTo-Json | Out-File "$PSScriptRoot\manifest.json";

	Exec { & git add "$PSScriptRoot\manifest.json"; }

	foreach ($psd1 in (Get-ChildItem "$RootDir\src\*\*" -Filter "*.psd1"))
	{
		$content = Get-Content $psd1 | Out-String;
		$content = $content -replace 'ModuleVersion(\s)*=(\s)*(''|")(?<ver>\d\.?)+(''|")', "ModuleVersion = '$value'";
		$content | Out-File $psd1 -Encoding utf8;
		Exec { & git add $($psd1.FullName); }
	}

	foreach ($proj in (Get-ChildItem "$RootDir\src" -Recurse -Filter "*.csproj" | Select-Object -ExpandProperty FullName))
	{
		$assemblyInfo = "$(Split-Path $proj -Parent)\Properties\AssemblyInfo.cs";
		$content = Get-Content $assemblyInfo | Out-String;
		$content = $content -replace '"(\d+\.?)+"', "`"$value`"";
		$content | Out-File $assemblyInfo;
		Exec {  & git add $assemblyInfo; }
	}

	Exec {
		& git commit -m "Increment the project's version number to $value";
		& git tag v$value;
	}
	Write-Host "`t* updated to version $value";
}

Task "Create-Packages" -alias "pack" -description "This task generates a nuget package for each project." `
-depends @("Init") -action {
	$version = $Manifest.version;
	$suffix = "";

	if (Test-Path $ArtifactsDir -PathType Container)
	{
		Remove-Item $ArtifactsDir -Recurse;
	}

	New-Item $ArtifactsDir -ItemType Directory | Out-Null;

	foreach ($proj in (Get-ChildItem "$RootDir\src\*\*" -Filter "*.*proj"))
	{
		$psd1 = [IO.Path]::ChangeExtension($proj.FullName, "psd1");
		$moduleName = [IO.Path]::GetFileNameWithoutExtension($proj.FullName);
		$dir = "$ArtifactsDir\$moduleName";

		if ((Test-Path $psd1 -PathType Leaf) -and ($proj.Extension -eq ".csproj"))
		{
			New-Item $dir -ItemType Directory | Out-Null;
			Get-ChildItem "$($proj.DirectoryName)\bin\$BuildConfiguration" | Copy-Item -Destination $dir;
		}
		elseif (Test-Path $psd1 -PathType Leaf)
		{
			New-Item $dir -ItemType Directory | Out-Null;
			Get-ChildItem "$($proj.DirectoryName)" -Filter "*.ps*1" | Copy-Item -Destination $dir;
		}
	}

	foreach ($psd1 in (Get-ChildItem "$ArtifactsDir" -Recurse -Filter "*.psd1"))
	{
		if (Test-Path $psd1 -PathType Leaf)
		{
			Update-ModuleManifest $psd1 `
			-ModuleVersion "$($version.major).$($version.minor).$($version.patch)" -PowerShellVersion "5.0" `
			-Author $Manifest.project.author -CompanyName $Manifest.project.author `
			-IconUri $Manifest.project.icon `
			-ProjectUri $Manifest.project.site `
			-LicenseUri $Manifest.project.license `
			-Copyright $Manifest.project.copyright;
		}
	}

	$nuspec = "$PSScriptRoot\buildbox.nuspec";
	$properties = "version=$($version.major).$($version.minor).$($version.patch);";

	if ([String]::IsNullOrEmpty($ReleaseTag))
	{ Exec { & $nuget pack $nuspec -OutputDirectory $ArtifactsDir -Properties $properties; } }
	else
	{ Exec { & $nuget pack $nuspec -OutputDirectory $ArtifactsDir -Properties $properties -Suffix $ReleaseTag; } }
}

Task "Publish-Packages" -alias "publish" -description "Publish all nuget packages to 'nuget.org' and 'powershell gallery'." `
-depends @("Create-Packages") -action {
	foreach ($package in (Get-ChildItem $ArtifactsDir -Recurse -Filter "*.nupkg" | Select-Object -ExpandProperty FullName))
	{
		if ([string]::IsNullOrEmpty($NuGetKey))
		{ Exec { & $nuget push $package -Source "https://api.nuget.org/v3/index.json"; } }
		else
		{ Exec { & $nuget push $package -Source "https://api.nuget.org/v3/index.json" -ApiKey $NuGetKey; } }
		Write-BreakLine;
	}

	if ((-not [String]::IsNullOrEmpty($PsGalleryKey)) -and ([String]::IsNullOrEmpty($ReleaseTag)))
	{
		foreach ($manifest in (Get-ChildItem $ArtifactsDir -Recurse -Filter "*.psd1"))
		{
			try
			{
				Push-Location $manifest.DirectoryName;
				Write-Host "publishing $($manifest.Name) ...";
				Publish-Module -Path $manifest.DirectoryName -NuGetApiKey $PsGalleryKey;
			}
			finally { Pop-Location; }
		}
	}
}