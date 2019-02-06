Join-Path $PSScriptRoot "*.psm1" | Get-Item | Import-Module -Force;

Describe ".NETCORE" {
	$context = New-TestEnvironment "netcore" -Data -Git;
	$invalidFile = Join-Path $context.SampleDir "*.json" | Resolve-Path | Get-Item;
	$validFile = Join-Path $context.SampleDir "netstandard.csproj" | Resolve-Path | Get-Item;

	Context "Test-NetcoreProjectFile" {
		It "should accept .netcore project file." {
			$validFile | Test-NetcoreProjectFile | Should Be $true;
			$validFile.FullName | Test-NetcoreProjectFile | Should Be $true;
			$invalidFile | Test-NetcoreProjectFile | Should Be $false;
		}
	}

	Context "Edit-NetcoreProjectFile" {
		$manifest = Join-Path $context.SampleDir "manifest.json" | Get-Item;

		It "should modify .netcore project file." {
			$validFile | Edit-NetcoreProjectFile $manifest;
			$validFile | Approve-File | Should Be $true;

			$validFile.FullName | Edit-NetcoreProjectFile $manifest.FullName;
			$validFile | Approve-File | Should Be $true;

			$obj = Get-Content $manifest | ConvertFrom-Json;
			$validFile | Edit-NetcoreProjectFile $obj;
			$validFile | Approve-File | Should Be $true;
		}
	}
}

Describe ".NET4+" {
	$context = New-TestEnvironment "net40" -Data -Git;
	$invalidFile = Join-Path $context.SampleDir "*.json" | Resolve-Path | Get-Item;
	$validFile = Join-Path $context.SampleDir "**/netframework.csproj" | Resolve-Path | Get-Item;

	Context "Test-NetFrameworkProjectFile" {
		It "should accept .net framework project file." {
			$validFile | Test-NetFrameworkProjectFile | Should Be $true;
			$validFile.FullName | Test-NetFrameworkProjectFile | Should Be $true;
			$invalidFile | Test-NetFrameworkProjectFile | Should Be $false;
		}
	}

	Context "Test-NetFrameworkProjectFile" {
		$manifest = Join-Path $context.SampleDir "manifest.json" | Get-Item;

		It "should modify .net framework project file." {
			$validFile | Edit-NetFrameworkProjectFile $manifest;
			$result = Get-Content (Join-Path (Split-Path $validFile -Parent) "Properties/AssemblyInfo.cs") | Out-String;
			$result | Approve-Results -TestName "net4-case1.cs" | Should Be $true;

			$validFile.FullName | Edit-NetFrameworkProjectFile $manifest.FullName;
			$result = Get-Content (Join-Path (Split-Path $validFile -Parent) "Properties/AssemblyInfo.cs") | Out-String;
			$result | Approve-Results -TestName "net4-case2.cs" | Should Be $true;

			$obj = Get-Content $manifest | ConvertFrom-Json;
			$obj.version.patch = 15;
			$validFile | Edit-NetFrameworkProjectFile $obj;
			$result = Get-Content (Join-Path (Split-Path $validFile -Parent) "Properties/AssemblyInfo.cs") | Out-String;
			$result | Approve-Results -TestName "net4-case3.cs" | Should Be $true;
		}
	}
}

Describe "VSIX" {
	$context = New-TestEnvironment "vsix" -Data -Git;
	$validFile = Join-Path $context.SampleDir "*.vsix*" | Resolve-Path | Get-Item;
	$invalidFile = Join-Path $context.SampleDir "*.json" | Resolve-Path | Get-Item;

	Context "Test-VSIXManifest" {
		It "should accept .vsix project manifest." {
			$validFile | Test-VSIXManifest | Should Be $true;
			$validFile.FullName | Test-VSIXManifest | Should Be $true;
			$invalidFile | Test-VSIXManifest | Should Be $false;
		}
	}

	Context "Edit-VSIXManifest" {
		$manifest = Join-Path $context.SampleDir "manifest.json" | Get-Item;

		It "should modify vsix manifest." {
			$validFile | Edit-VSIXManifest $manifest;
			$validFile | Approve-File | Should Be $true;

			$validFile.FullName | Edit-VSIXManifest $manifest.FullName;
			$validFile | Approve-File | Should Be $true;

			$obj = Get-Content $manifest | ConvertFrom-Json;
			$validFile | Edit-VSIXManifest $obj;
			$validFile | Approve-File | Should Be $true;
		}
	}
}

Describe "JS" {
	$context = New-TestEnvironment "js" -Data -Git;
	$validFile = Join-Path $context.SampleDir "*.json" | Resolve-Path | Get-Item;
	$invalidFile = Join-Path $context.SampleDir "*.vsix*" | Resolve-Path | Get-Item;

	Context "Test-PackageJson" {
		It "should accept package.json file." {
			$validFile | Test-PackageJson | Should Be $true;
			$validFile.FullName | Test-PackageJson | Should Be $true;
			$invalidFile | Test-PackageJson | Should Be $false;
		}
	}

	Context "Edit-PackageJson" {
		$manifest = Join-Path $context.SampleDir "manifest.json" | Get-Item;

		It "should modify package.json file." {
			$validFile | Edit-PackageJson $manifest;
			$validFile | Approve-File | Should Be $true;

			$validFile.FullName | Edit-PackageJson $manifest.FullName;
			$validFile | Approve-File | Should Be $true;

			$obj = Get-Content $manifest | ConvertFrom-Json;
			$validFile | Edit-PackageJson $obj;
			$validFile | Approve-File | Should Be $true;
		}
	}
}

Describe "PS" {
	$context = New-TestEnvironment "posh" -Data -Git;
	$validFile = Join-Path $context.SampleDir "*.psd1" | Resolve-Path | Get-Item;

	Context "Edit-PowershellManifest" {
		$manifest = Join-Path $context.SampleDir "manifest.json" | Get-Item;

		It "should modify .psd1 manifest file." {
			$validFile | Edit-PowershellManifest $manifest;
			$validFile | Approve-File | Should Be $true;

			$validFile.FullName | Edit-PowershellManifest $manifest.FullName;
			$validFile | Approve-File | Should Be $true;

			$obj = Get-Content $manifest | ConvertFrom-Json;
			$validFile | Edit-PowershellManifest $obj;
			$validFile | Approve-File | Should Be $true;
		}
	}
}

Describe "Test-Git" {
	$context = New-TestEnvironment "git";

	It "can determine if git is installed." {
		Test-Git | Should Be $true;
	}
}