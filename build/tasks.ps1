<#
.SYNOPSIS
Psake build tasks.
#>

Properties {
	# Paths
	$RootDir = (Split-Path $PSScriptRoot -Parent);
	$ArtifactsDir = "$RootDir\artifacts";

	# Tools
	$nuget = "";

	# Enviroment Args
	$Branch = "";
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
	foreach ($folder in @($ArtifactsDir))
	{
		if (Test-Path $folder -PathType Container)
		{ Remove-Item $folder -Recurse -Force; }

		New-Item $folder -ItemType Directory | Out-Null;
	}
	
	foreach ($psm1 in (Get-ChildItem "$RootDir\build" -Filter "*.psm1" | Select-Object -ExpandProperty FullName))
	{
		Import-Module $psm1 -Force;
		Write-Host "`t* $(Split-Path $psm1 -Leaf) imported.";
	}

	$pester = Get-Item "$RootDir\packages\Pester.*\tools\Pester.psm1" | Select-Object -ExpandProperty FullName;
	Import-Module $pester;
	Write-Host "`t* pester imported.";
}


Task "Cleanup" -description "This task releases all resources." -action {
	
}


Task "setup" -description "Run this task to help configure your local enviroment for development." `
-depends @("Init") -action {
	Write-Host "You will need a ftp server to run the winscp module tests. Provide the following so I can build a connection string" -ForegroundColor Cyan;
	$address = Read-Host "host name";
	$user = Read-Host "username";
	$password = Read-Host "password";

	$json = @"
{
  "ftp":
  {
	"host": "$address",
	"user": "$user",
	"password": "$password"
  }
}
"@ | Out-File "$RootDir\tests\MSTest.Buildbox\credentials.json";
	Write-Host "`t* created '$RootDir\tests\Tests.Buildbox\credentials.json'";
}


Task "Build-Solution" -alias "compile" -description "This task compile the solution." `
-depends @("Init") -action {
	Assert ("Debug", "Release" -contains $BuildConfiguration) "`$BuildConfiguration was '$BuildConfiguration' but expected 'Debug' or 'Release'.";

	$sln = Get-Item "$RootDir\*.sln" | Select-Object -ExpandProperty FullName;
	Write-Breakline "MSBUILD";
	Exec { msbuild $sln "/p:Configuration=$BuildConfiguration;Platform=Any CPU"  "/v:minimal"; };
	Write-BreakLine;
}


Task "Run-Pester" -alias "pester" -description "This task invoke all selected pester tests." `
-depends @("Init", "Build-Solution") -action {
	$totalFailedTests = 0;
	if ([String]::IsNullOrEmpty($TestName))
	{ 
		foreach($script in (Get-ChildItem "$RootDir\tests" -Recurse -Filter "*.tests.ps1" | Select-Object -ExpandProperty FullName))
		{
			Invoke-Pester -Script $script -EnableExit;
		}
	}
	else
	{
		$script = Get-ChildItem "$RootDir\tests" -Recurse -Filter "*$TestName*.ps1" | Select-Object -ExpandProperty FullName -First 1;
		Invoke-Pester -Script $script;
	}
}


Task "Run-Tests" -alias "test" -description "This task runs all tests." `
-depends @("Build-Solution") -action {
	Write-BreakLine "VSTEST";
	foreach ($proj in (Get-ChildItem "$RootDir\tests\MSTest.Buildbox" -Filter "*.csproj" | Select-Object -ExpandProperty FullName))
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
	$version = $config.version;
	$version.patch = ([Int]::Parse($version.patch) + 1);
	$value = "$($version.major).$($version.minor).$($version.patch)";
	$config | ConvertTo-Json | Out-File "$PSScriptRoot\config.json";

	Exec { & git add "$PSScriptRoot\config.json"; }

	foreach ($proj in (Get-ChildItem "$RootDir\src" -Recurse -Filter "*.*proj" | Select-Object -ExpandProperty FullName))
	{
		$extension = [IO.Path]::GetExtension($proj);

		if ($extension -eq ".csproj")
		{
			$assemblyInfo = "$(Split-Path $proj -Parent)\Properties\AssemblyInfo.cs";
			$content = Get-Content $assemblyInfo | Out-String;
			$content = $content -replace '"(\d+\.?)+"', "`"$value`"";
			$content | Out-File $assemblyInfo;

			Exec {  & git add $assemblyInfo; }
		}
		
		if ($extension -eq ".pssproj")
		{
			[string]$manifest = [IO.Path]::ChangeExtension($proj, "psd1");
			if (Test-Path $manifest -PathType Leaf)
			{
				$content = Get-Content $manifest | Out-String;
				$content = $content -replace 'ModuleVersion(\s)*=(\s)*(''|")(?<ver>\d\.?)+(''|")', "ModuleVersion = '$value'";
				$content | Out-File $manifest -Encoding utf8;

				Exec { & git add $manifest; }
			}
		}
	}

	Exec {
		& git commit -m "Increment the project's version number to $value";
		& git tag v$value;
	}
	Write-Host "`t* updated to version $value";
}


Task "Create-Packages" -alias "pack" -description "This task generates a nuget package for each project." `
-depends @("Init") -action {

	$nuspec = "$RootDir\buildbox.nuspec";
	if (Test-Path $nuspec -PathType Leaf)
	{
		$outDir = "$ArtifactsDir\nupkgs";
		$version = $config.version;

		$properties = "";
		$properties += "Configuration=$BuildConfiguration";
		$properties += ";Version=$($version.major).$($version.minor).$($version.patch)";
		
		Write-BreakLine "NUGET";
		if ([string]::IsNullOrEmpty($ReleaseTag))
		{ Exec { & $nuget pack $nuspec -OutputDirectory $outDir -Prop $properties; } }
		else
		{ Exec { & $nuget pack $nuspec -OutputDirectory $outDir -Prop $properties -Suffix $ReleaseTag; } }
	}
}


Task "Publish-Packages" -alias "publish" -description "Publish all nuget packages to 'nuget.org' and 'powershell gallery'." `
-depends @("Run-Tests", "Create-Packages") -action {

	foreach ($package in (Get-ChildItem $ArtifactsDir -Recurse -Filter "*.nupkg" | Select-Object -ExpandProperty FullName))
	{
		
		if ([string]::IsNullOrEmpty($NuGetKey))
		{ Exec { & $nuget push $package -Source "https://api.nuget.org/v3/index.json"; } }
		else
		{ Exec { & $nuget push $package -Source "https://api.nuget.org/v3/index.json" -ApiKey $NuGetKey; } }
		Write-BreakLine;
	}
}
