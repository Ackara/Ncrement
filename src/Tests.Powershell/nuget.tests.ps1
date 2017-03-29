Describe "Install-NuGet" {
	$srcDir = Split-Path $PSScriptRoot -Parent;
	$nuget = "$srcDir\Scripts\Install-NuGet.ps1";
	$sampleDir = "$PSScriptRoot\Samples\nuget";

	It "should exist" {
		$nuget | Should Exist;
	}

	It "should download nuget.exe in the default directory." {
		$defaultPath = "$PSScriptRoot\bin\nuget\nuget.exe";
		if (Test-Path $defaultPath -PathType Leaf) { Remove-Item $defaultPath; }

		try
		{
			Push-Location $PSScriptRoot;
			& $nuget;
		}
		finally { Pop-Location; }

		$defaultPath | Should Exist;
	}

	It "should download nuget.exe in a specified directory." {
		$targetPath = "$PSScriptRoot\bin\downloads\nuget.exe";
		if (Test-Path $targetPath -PathType Leaf) { Remove-Item $targetPath; }

		& $nuget -Version "4.0.0" -OutFile $targetPath;

		$targetPath | Should Exist;
	}
	
	It "should overwrite the file when the flag is set." {
		$mockFile = "$env:TEMP\nuget-mock.exe";
		"content" | Out-File $mockFile;
		$before = (Get-Item $mockFile).Length;
	
		& $nuget -OutFile $mockFile -Overwrite;
		$after = (Get-Item $mockFile).Length;

		$before | Should BeLessThan $after;
		$after | Should BeGreaterThan 1MB;
	}
}