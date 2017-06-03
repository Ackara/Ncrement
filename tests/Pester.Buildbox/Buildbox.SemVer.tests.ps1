Param ([string]$BuildConfiguration="Debug")
Import-Module "$PSScriptRoot\utils.psm1" -Force;

$rootDir = Get-RootDir;
$module = "$rootDir\src\Buildbox.SemVer\bin\$BuildConfiguration\*buildbox.semver.dll";
Import-Module $module -Force;

$sampleDir = "$(Split-Path $PSScriptRoot -Parent)\MSTest.Buildbox\Samples\semver";
$testResultsDir = "$env:TEMP\Buildbox\TestResults\pester\semver";
$testResultsIn = "$testResultsDir\in";
$testResultsOut = "$testResultsDir\out";
if (Test-Path $testResultsDir -PathType Container) { Remove-Item $testResultsDir -Recurse -Force; }
foreach ($folder in @($testResultsIn, $testResultsOut))
{
	New-Item $folder -ItemType Directory | Out-Null;
}

$defaultSettingFile = "$rootDir\src\Buildbox.SemVer\bin\$BuildConfiguration\semVer.json";

Describe "Get-VersionNumber" {
	It "should generate a default settings file if it do not exist." {
		If (Test-Path $defaultSettingFile -PathType Leaf) { Remove-Item $defaultSettingFile; }
		$version = Get-VersionNumber;
		$defaultSettingFile | Should Exist;
	}

	It "should return a [versionNumber] object when invoked."{
		$version = Get-VersionNumber;
		$version  | Should Not BeNullOrEmpty;
	}
}

Describe "Step-VersionNumber" {
	$version = Get-VersionNumber;

	It "should increment the patch number only when the patch switch is set." {
		$result = Step-VersionNumber -Patch;
		$result.Patch | Should Be ($version.Patch + 1);
		$result.Minor | Should Be $version.Minor;
		$result.Major | Should Be $version.Major;
		$version = $result;
	}

	It "should increment the minor number and reset the patch number when the minor switch is set." {
		$result = Step-VersionNumber -Minor;
		$result.Patch | Should Be 0;
		$result.Minor | Should Be ($version.Minor + 1);
		$result.Major | Should Be $version.Major;
		$version = $result;
	}

	It "should increment the major number and reset the minor and patch numbers when the major switch is set." {
		$result = Step-VersionNumber -Major;
		$result.Patch | Should Be 0;
		$result.Minor | Should Be 0;
		$result.Major | Should Be ($version.Major + 1);
	}
}

Describe "Update-VersionNumber" {
	Context "using default settings" {
		$workingDir = "$testResultsIn\default";
		if (-not (Test-Path $workingDir -PathType Container)) { New-Item $workingDir -ItemType Directory; }

		Copy-Item "$sampleDir\*" $workingDir -Recurse;
		if (Test-Path $defaultSettingFile -PathType Leaf) { Remove-Item $defaultSettingFile; }
		$results = Update-VersionNumber $workingDir -Patch -ReleaseTag "";

		It "should return updated files to the pipeline." {
			$results | Should Not BeNullOrEmpty;
		}

		It "should increment the dotnet project version number." {
			$approved = Approve-File "$workingDir\dotnet_project\Properties\AssemblyInfo.cs" "update-versionNumber__dotnet_projectA";
			$approved | Should Be $true;
		}

		It "should increment the dotnet core project version number." {
			$approved = Approve-File "$workingDir\dotnetcore_project\dotnetcore_project.csproj" "update-versionNumber__dotnet_core_projectA";
			$approved | Should Be $true;
		}

		It "should increment the powershell module/project version number." {
			$approved = Approve-File "$workingDir\powershell_project\PowerShellModuleProject1.psd1" "update-versionNumber__powershell_projectA";
			$approved | Should Be $true;
		}
	}

	Context "using custom settings file" {
	}
}

Describe "Get-BranchSuffixCmdlet" {
	It "should return an empty string when 'master' is passed" {
		$result = Get-BranchSuffix "master";
		$result | Should Be "";
	}

	It "should return the string 'alpha' when a random string is passed" {
		$result1 = Get-BranchSuffix "random";
		$result2 = "" | Get-BranchSuffix;

		$result1 | Should Be "alpha";
		$result2 | Should Be "alpha";
	}
}