Join-Path $PSScriptRoot "*.psm1" | Get-Item | Import-Module -Force;

Describe "New-NcrementManifest" {
	It "should return new manifest" {
		$manifest = New-NcrementManifest;
		$manifest | ConvertTo-Json | Approve-Results -testName "new-ncrementManifest.json" | Should Be $true;
	}
}

Describe "Step-NcrementVersionNumber" {
	$context = New-TestEnvironment "data" -Data;
	$manifest = Join-Path $context.SampleDir "manifest.json" | Get-Item;

	It "should increment major version number." {
		$case1 = Get-Content $manifest | ConvertFrom-Json;
		$version = ($case1 | Step-NcrementVersionNumber -Major).version;

		$version.major | Should Be 2;
		$manifest | Step-NcrementVersionNumber -Major | ConvertTo-Json | Approve-Results -TestName "step-major.json" | Should Be $true;
		$manifest.FullName | Step-NcrementVersionNumber -Major | ConvertTo-Json | Approve-Results -TestName "step-major.json" | Should Be $true;
	}

	It "should increment minor version number." {
		$case2 = Get-Content $manifest | ConvertFrom-Json;
		$version = ($case2 | Step-NcrementVersionNumber -Minor).version;

		$version.minor | Should Be 3;
		$manifest | Step-NcrementVersionNumber -Minor | ConvertTo-Json | Approve-Results -TestName "step-minor.json" | Should Be $true;
		$manifest.FullName | Step-NcrementVersionNumber -Minor | ConvertTo-Json | Approve-Results -TestName "step-minor.json" | Should Be $true;
	}

	It "should increment patch version number." {
		$case3 = Get-Content $manifest | ConvertFrom-Json;
		$version = ($case3 | Step-NcrementVersionNumber -Patch).version;

		$version.patch | Should Be 4;
		$manifest | Step-NcrementVersionNumber -Patch | ConvertTo-Json | Approve-Results -TestName "step-patch.json" | Should Be $true;
		$manifest.FullName | Step-NcrementVersionNumber -Patch | ConvertTo-Json | Approve-Results -TestName "step-patch.json" | Should Be $true;
	}
}

Describe "Update-ProjectFile" {
	$context = New-TestEnvironment "update" -Data -Git;
	$manifest = Join-Path $context.SampleDir "manifest.json" | Get-Item;

	It "should update all project files." {
		foreach ($file in (Get-ChildItem $context.SampleDir -Recurse -File -Filter "*"))
		{
			Write-Host "`t=> testing: $($file.FullName)" -ForegroundColor DarkGray;
			$before = Get-Content $file.FullName | Out-String;
			$after = $file | Update-ProjectFile $manifest -Major -Commit -Verbose;
			if ($after)
			{
				Get-Content $after.FullName | Out-String | Should Match "2.0.0";
			}
		}
	}
}