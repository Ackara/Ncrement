Join-Path $PSScriptRoot "*.psm1" | Resolve-Path | Import-Module -Force;
$context = New-TestEnvironment;
$context.ModulePath | Import-Module -Force;

Describe "New-Manifest" {
	It "PS: can create manifest" {
		$manifest = New-NcrementManifest -Title "Pester";
		$manifest | Should Not Be $null;
		$manifest.Name | Should Be "Pester";
	}
}

Describe "Step-Version" {
	$manifestPath = Join-Path $context.SampleDirectory "manifest.json";
	$manifest = Get-Content $manifestPath | ConvertFrom-Json;

	It "PS: can increment version number" {
		$case1 = $manifestPath | Step-NcrementVersionNumber -Major:$false -Minor:$false -Patch;
		$case1.Version.Patch | Should Be 4;

		$case2 = $manifest | Step-NcrementVersionNumber;
		$case2.Version.Patch | Should Be 3;
	}
}

Describe "Select-VersionNumber" {
	$manifestPath = Join-Path $context.SampleDirectory "manifest.json" | Resolve-Path;
	$manifest = Get-Content $manifestPath | ConvertFrom-Json;

	It "PS: can get maniest version number" {
		$result1 = $manifest | Select-NcrementVersionNumber -Verbose;
		$result1 | Should Be "0.0.3";

		$result2 = $manifestPath | Select-NcrementVersionNumber -format "z.y.x" -Verbose;
		$result2 | Should Be "3.0.0";
	}
}

Describe "Edit-Manifest" {
	[string]$manifestPath = Join-Path ([IO.Path]::GetTempPath()) "pester-manifest.json";
	Join-Path $context.SampleDirectory "manifest.json" | Resolve-Path | Copy-Item -Destination $manifestPath -Force;
	$manifest = Get-Content $manifestPath | ConvertFrom-Json;
	$manifest.Name = "Changed";

	It "PS: Can edit manifest file" {
		$result = $manifest | ConvertTo-Json;
		Approve-Results $result "edit-manifest" | Should Be $true;
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

	It "PS: can update project file with powershell" {
		$projectFile | Update-NcrementProjectFile $manifestPath -Commit -Message "test" -Verbose;
		$projectFile | Approve-File | Should Be $true;
	}
}

#Describe "Basic Usage" {
#	# Creating a working directory.
#	[string]$rootFolder = $context.TempDirectory;
#	if (Test-Path $rootFolder) { Remove-Item $rootFolder -Recurse -Force; }
#	New-Item $rootFolder -ItemType Directory | Out-Null;

#	# Create manifest.
#	$manifest = New-NcrementManifest -Title "Pester";
#	It "PS: (Step 1) can create new manifest" {
#		$manifest.Name | Should Be "Pester";
#	}

#	# Save manifest.
#	$manifestPath = Join-Path $rootFolder "manifest.json";
#	$manifest | ConvertTo-Json | Out-File -FilePath $manifestPath -Encoding utf8;

#	# Increment version number
#	$manifest = $manifestPath | Step-NcrementVersionNumber -Patch;
#	$manifest | ConvertTo-Json | Out-File -FilePath $manifestPath -Encoding utf8;

#	# Get version number
#	$version = $manifestPath | Select-NcrementVersionNumber;
#	Write-Host "v: $version";
#	$manifest | Write-Host;
#}