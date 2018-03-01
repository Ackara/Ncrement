Import-Module "$PSScriptRoot\test.psm1" -Force;

Describe "Update-NcrementProjectFile" {
	Context "Help" {
		It "should display help menu." {
			$help = (help Update-NcrementProjectFile -Full | Out-String);
			$help | Should Not BeNullOrEmpty;
			#Approve-Results $help "Update-NcrementProjectFile_help.txt" | Should Be $true;
		}
	}

	Context "Command" {
		$context = New-TestEnvironment;
		$manifest = Get-NcrementManifest $context.TestFiles;
		$manifest.Name = "Automated Testing";
		$result = $manifest | Update-NcrementProjectFile $context.TestFiles;

		It "should update netcore project." {
			$target = Join-Path $context.TestFiles "netstandard.csproj";
			$result.ModifiedFiles.Contains($target) | Should Be $true;
			Approve-File $target | Should Be $true;
		}

		It "should update netFramework project." {
			$target = Join-Path $context.TestFiles "netframework\Properties\AssemblyInfo.cs";
			$result.ModifiedFiles.Contains($target) | Should Be $true;
			Approve-File $target | Should Be $true;
		}

		It "should update vsix project." {
			$target = Join-Path $context.TestFiles "extension.vsixmanifest";
			$result.ModifiedFiles.Contains($target) | Should Be $true;
			Approve-File $target | Should Be $true;
		}

		It "should update powershell manifest" {
			$target = Join-Path $context.TestFiles "mock.psd1";
			$content = (Get-Content $target | Out-String);
			$content = $content.Substring($content.IndexOf('@'));

			$result.ModifiedFiles.Contains($target) | Should Be $true;
			Approve-Results $content (Split-Path $target -Leaf) | Should Be $true;
		}

		It "should update package.json" {
			$target = Join-Path $context.TestFiles "package.json";
			$result.ModifiedFiles.Contains($target) | Should Be $true;
			Approve-File $target | Should Be $true;
		}

		It "should not commit modified files to source control" {
			(&git status | Out-String) | Should BeLike "*changes not staged for commit*";
		}
	}

	Context "Git" {
		[string]$status;
		$context = New-TestEnvironment "Update-NcrementProjectFile_git";

		$manifest = Get-NcrementManifest $context.TestFiles;
		$results = $manifest | Update-NcrementProjectFile $context.TestFiles -Tag -Commit;

		Push-Location $context.TestFiles;
		try { $status = (&git status | Out-String); }
		finally { Pop-Location; }

		It "should commit all modified files to source control." {
			$status | Should BeLike "*nothing to commit*";
		}
	}
}