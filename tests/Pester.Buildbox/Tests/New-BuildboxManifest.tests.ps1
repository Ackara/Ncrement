Import-Module "$PSScriptRoot\helper.psm1" -Force;
$testContext = New-TestEnviroment;
Import-Module $testContext.Module -Force;

Describe "Buildbox" {
	#help New-BuildboxManifest -ShowWindow;
	Context "New-BuildboxManifest" {
        It "New-BuildboxManifest should return a Manifest object when no args are passed." {
            try
            {
                Push-Location $testContext.TestResultsDir;
                $result = New-BuildboxManifest;
                $result | Should BeOfType [Acklann.Buildbox.Versioning.Manifest];
				"$($testContext.TestResultsDir)\manifest.json" | Should Exist;

                if (Test-Path $result) { Remove-Item $result -Force; }
            }
            finally { Pop-Location; }
        }

		It "New-BuildboxManifest should return Manifest object when a directory is passed." {
            $dir = Get-Item $testContext.TestResultsDir;
            $result = New-BuildboxManifest $dir;
			$result.FullPath | Should Exist;
            $result | Should BeOfType [Acklann.Buildbox.Versioning.Manifest];
		}

        It "New-BuildboxManifest should return a Manifest object when a file path is passed." {
            $newPath = [IO.Path]::Combine($testContext.TestResultsDir, "test.json");
            $result = New-BuildboxManifest $newPath;
            $result | Should BeOfType [Acklann.Buildbox.Versioning.Manifest];
			$newPath | Should Exist;
        }

		It "New-BuildboxManifest should overwrite an existing manfest.json file when the Force switch is present" {
			$path = "$($testContext.TestResultsDir)\overwrite.json";
			$manifest = New-Object Acklann.Buildbox.Versioning.Manifest;
			$manifest.Version.Major = 5;
			$manifest.Save($path);
			$result1 = $path | New-BuildboxManifest -Force;

			$result1.Version.Major | Should Be 1;
		}

		It "New-BuildboxManifest should throw an exceoption when an existing file already exist." {
			$path = "$($testContext.TestResultsDir)\exception.json";
			$manifest = New-Object Acklann.Buildbox.Versioning.Manifest;
			$manifest.Version.Major = 5;
			$manifest.Save($path);
			{ New-BuildboxManifest $path } | Should Throw;
		}
	}
}

if (Get-Module Buildbox) { Remove-Module Buildbox; }