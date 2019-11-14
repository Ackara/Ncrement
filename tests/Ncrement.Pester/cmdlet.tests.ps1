Join-Path $PSScriptRoot "*.psm1" | Resolve-Path | Import-Module -Force;
$context = New-TestEnvironment;
$context.ModulePath | Import-Module -Force;

Describe "New-Manifest" {
	It "can create manifest instance from powershell" {
		$manifest = New-NcrementManifest -Title "Pester" -Verbose;
		$manifest | Should Not Be $null;
		$manifest.Name | Should Be "Pester";
	}
}

Describe "Step-Version" {
	$manifestPath = Join-Path $context.SampleDirectory "manifest.json";
	$manifest = Get-Content $manifestPath | ConvertFrom-Json;

	It "can increment version from powershell" {
		$result = $manifest | Step-NcrementVersionNumber -Major;
		$result.Version.Major | Should Be 1;
		$result.Version.Patch | Should Be 0;
	}
}

Describe "Update-ProjectFile" {
	$manifestPath = Join-Path $context.SampleDirectory "manifest.json" | Resolve-Path;
	$manifest = Get-Content $manifestPath | ConvertFrom-Json;

	$tempFolder = Join-Path ([IO.Path]::GetTempPath()) "ncremnet-pester/$([Guid]::NewGuid().ToString())";
	New-Item $tempFolder -ItemType Directory | Out-Null;

	try
	{
		Push-Location $tempFolder;

		&git init;

		$readme = Join-Path $tempFolder "README.md";
		$sourceFile = Join-Path $context.SampleDirectory "projects/empty_netframework.csproj";
		$projectFile = Join-Path $tempFolder (Split-Path $sourceFile -Leaf);
		Copy-Item $sourceFile -Destination $projectFile;

		Copy-Item $manifestPath -Destination $tempFolder;
		$manifestPath = Join-Path $tempFolder (Split-Path $manifestPath -Leaf);

		Out-File -FilePath $readme -InputObject "# Ncrement";
		&git add --all; &git commit -m "init";
	}
	finally { Pop-Location; }
	#Invoke-Item $tempFolder;
	
	It "can update project file with powershell" {
		$projectFile | Update-NcrementProjectFile $manifestPath -Commit -Message "test" -Verbose;
		$projectFile | Approve-File | Should Be $true;
	}
}

Describe "Select-VersionNumber" {
	$manifestPath = Join-Path $context.SampleDirectory "manifest.json" | Resolve-Path;
	$manifest = Get-Content $manifestPath | ConvertFrom-Json;

	It "can get maniest version number" {
		$result1 = $manifest | Select-NcrementVersionNumber -Verbose;
		$result1 | Should Be "0.0.3";

		$result2 = $manifestPath | Select-NcrementVersionNumber -format "z.y.x" -Verbose;
		$result2 | Should Be "3.0.0";
	}
}