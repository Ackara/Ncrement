Import-Module "$PSScriptRoot\helper.psm1" -Force;
$testContext = New-TestEnviroment;
Import-Module $testContext.Module -Force;
$testName = "Update-ProjectManifests";

Describe "Buildbox" {
	Context "Update-ProjectManifests" {
		$repo = "$($env:TEMP)\Buildbox";
		try
		{
			if (Test-Path $repo) { Remove-Item $repo -Force -Recurse; }
			New-Item $repo -ItemType Directory | Out-Null;
			Copy-Item $testContext.TestDataDir -Destination $repo -Recurse -Force -ErrorAction Stop;
			Push-Location $repo;
			& git init $repo;

			$manifest = New-BuildboxManifest;
			$result = $manifest | Update-ProjectManifests $repo -Major -Commit -Tag;

			It "Update-ProjectManifests should update an netstandard project file" {
				$projectFile = Get-ChildItem $repo -Filter "*netstandard.csproj" -Recurse | Select-Object -ExpandProperty FullName -First 1;
				$fileWasApproved = Approve-File $projectFile "$($testName)_netstandard";

				$fileWasApproved | Should Be $true;
			}

			It "Update-ProjectManifests should update an dotnet framework project file" {
				$projectFile = Get-ChildItem $repo -Filter "*AssemblyInfo.cs" -Recurse | Select-Object -ExpandProperty FullName -First 1;
				$fileWasApproved = Approve-File $projectFile "$($testName)_dotnet";

				$fileWasApproved | Should Be $true;
			}

			It "Update-ProjectManifests should commit updated files to the git repository" {
				try
                {
                    (& git log);
                }
                catch
                {
                    throw "files were not commited.";
                }
			}

			It "Update-ProjectManifests should return a results object" {
				$result.ModifiedFiles.Length | Should Be 3;
				$result.CommittedChanges| Should Be $true;
				$result.Manifest | Should Not Be $null;
			}
		}
		finally
		{
			Pop-Location;
		}
	}
}