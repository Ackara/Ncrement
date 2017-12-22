function New-TestEnvironment()
{
	$testName = [IO.Path]::GetFileNameWithoutExtension($MyInvocation.PSCommandPath);

	$rootDir = $PSScriptRoot;
	for ($i = 0; $i -lt 2; $i++) { $rootDir = Split-Path $rootDir -Parent; }

	$testResultsDir = "$rootDir\TestResults\$testName";
	if (Test-Path $testResultsDir) { Remove-Item $testResultsDir -Recurse -Force; }
	New-Item $testResultsDir -ItemType Directory | Out-Null;

	$testDataDir = "$testResultsDir\TestData";
	Copy-Item "$PSScriptRoot\TestData" -Destination $testDataDir -Recurse;

	return New-Object PSObject -Property @{
		"TestName"=$testName;
		"TestDir"=$testResultsDir;
		"TestDataDir"=$testDataDir;
		"ModulePath"=(Get-Item "$rootDir\src\*\*.psd1").FullName;
	};
}

function Approve-File([string]$receivedFile)
{
	if (Test-Path $receivedFile -PathType Leaf)
	{
		$approvalTestsDir = "$PSScriptRoot\Tests\ApprovalTests";
		if (-not (Test-Path $approvalTestsDir)) { New-Item $approvalTestsDir -ItemType Directory | Out-Null; }

		$ext = [IO.Path]::GetExtension($receivedFile);
		$filename = [IO.Path]::GetFileNameWithoutExtension($receivedFile);
		$approvedFile = "$approvalTestsDir\$filename.approved$ext";
		if (-not (Test-Path $approvedFile)) { New-Item $approvedFile -ItemType File | Out-Null; }

		$diff;
		try
		{
			$diff = Compare-Object (Get-Content $receivedFile) (Get-Content $approvedFile);
			if ($diff -ne $null) { throw "This file is not approved."; }
		}
		catch
		{
			Write-Host $diff;
			Write-Host "Copy-Item `"$receivedFile`" `"$approvedFile`";";
			Invoke-Item $receivedFile;
			return $false;
		}
	}
	else { throw "Could not find the recieved file at '$receivedFile'." }
	return $true;
}

function Approve-Text([string]$text, [string]$fileName)
{
	$recievedFile = "";
	if ([string]::IsNullOrEmpty($fileName))
	{
		$recievedFile = [IO.Path]::GetTempFileName();
	}
	else
	{
		$recievedFile = "$env:TEMP\$fileName";
	}
	$text | Out-File $recievedFile -Encoding utf8 -Force;
	$approved = Approve-File $recievedFile;
	if ($approved -eq $true) { return $approved; } else { throw "The file was not approved."; }
}