Import-Module "$(Split-Path $PSScriptRoot -Parent)\config.psm1" -Force
$context = New-TestEnvironment -useTemp;
Import-Module $context.ModulePath -Force;

Describe "Update-ProjectManifests" {
	Push-Location $context.TestDir;

	&git init;
	&git add *;
	&git commit -m init;
	
	$manifestPath = "$($context.TestDataDir)\manifest-full.json";
	$result = Get-Item $manifestPath | Get-BuildboxManifest | Update-ProjectManifests $context.TestDir -Commit -Tag -Minor;

	Context "Update Project" {
		It "should increment manifest version number" {
			$result.Manifest.Version.ToString() | Should Be "1.3.0";
			{ Approve-File $manifestPath } | Should Not Throw;
		}

		It "should update a .net core project." {
			$csprojFile = Get-Item "$($context.TestDataDir)\*standard*.csproj";
			{ Approve-File $csprojFile.FullName } | Should Not Throw;
		}

		It "should update a .net 4+ project" {
			$csprojFile = Get-Item "$($context.TestDataDir)\*\*\*Info.cs";
			{ Approve-File $csprojFile.FullName } | Should Not Throw;
		}

		It "should update a vsix project manifest" {
			$csprojFile = Get-Item "$($context.TestDataDir)\*.vsixmanifest";
			{ Approve-File $csprojFile.FullName } | Should Not Throw;
		}

		It "should update a powershell module manifest" {
			$psManifest = Get-Item "$($context.TestDataDir)\*.psd1";
			{ Approve-File $psManifest.FullName } | Should Not Throw;
		}
	}

	Context "Git" {
		It "should return a list of the modified files." {
			$result.ModifiedFiles.Count | Should BeGreaterThan 2;
		}

		It "should commit modified files to source control" {
			$stauts = &git status | Out-String;
			$stauts | Should Match "nothing to commit";
		}

		It "should tag commit with version number" {
			$tag = &git tag | Out-String;
			$tag | Should Match "v$($result.Manifest.Version.ToString())";
		}
	}
	Pop-Location;
}