#
# This is a PowerShell Unit Test file.
# You need a unit test framework such as Pester to run PowerShell Unit tests.
# You can download Pester from http://go.microsoft.com/fwlink/?LinkID=534084
#

Import-Module "$PSScriptRoot\helper.psm1" -Force;

$rootDir = Get-RootDir;
$sampleDir = "$(Split-Path $PSScriptRoot -Parent)\MSTest.Buildbox\Samples\semver";
$testResultsDir = "$rootDir\TestResults\pester-$((Get-Date).ToString('yyMMddHHmmss'))\semver";
$testResultsIn = "$testResultsDir\in";
$testResultsOut = "$testResultsDir\out";
foreach ($folder in @($testResultsIn, $testResultsOut))
{
	New-Item $folder -ItemType Directory | Out-Null;
}

$defaultSettingFile = "$testResultsOut\semver.json";
Get-ChildItem "$rootDir\src\*Buildbox.SemVer\bin\*" -Recurse | Copy-Item -Destination $testResultsOut;
$module = Get-Item "$testResultsOut\*.psd1";
Import-Module $module.FullName -Force;

Describe "Buildbox.SemVer" {
	Context "Get-VersionNumber" {
		It "should generate a default settings file if it do not exist." {
			$version = Get-VersionNumber;
			$defaultSettingFile | Should Exist;
		}

		It "should return a [versionNumber] object when invoked."{
			$version = Get-VersionNumber;
			$version | Should Not BeNullOrEmpty;
			$version | Should BeOfType Acklann.Buildbox.SemVer.VersionInfo;
		}
	}

	Context "Step-VersionNumber" {
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

	Context "Update-VersionNumber" {
		$workingDir = "$testResultsIn\default";
		if (-not (Test-Path $workingDir -PathType Container)) { New-Item $workingDir -ItemType Directory; }

		Copy-Item "$sampleDir\*" $workingDir -Recurse;
		if (Test-Path $defaultSettingFile -PathType Leaf) { Remove-Item $defaultSettingFile; }
		$results = Update-VersionNumber $workingDir -Patch -ReleaseTag "";

		It "should return updated files to the pipeline." {
			$results | Should Not BeNullOrEmpty;
		}
	}

	Context "Get-BranchSuffixCmdlet" {
		It "should return an empty string when 'master' is passed" {
			$result = Get-BranchSuffix "master";
			$result | Should BeNullOrEmpty;
		}
	}
}