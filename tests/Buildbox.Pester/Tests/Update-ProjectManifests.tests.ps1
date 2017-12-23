Import-Module "$(Split-Path $PSScriptRoot -Parent)\config.psm1" -Force
$context = New-TestEnvironment -useTemp;
Import-Module $context.ModulePath -Force;

Describe "Update-ProjectManifests" {
	#Push-Location $context.TestDir;

	#&git status | Write-Host;
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
			#{ Approve-File $psManifest.FullName } | Should Not Throw;
		}
	}
	#Pop-Location;
}