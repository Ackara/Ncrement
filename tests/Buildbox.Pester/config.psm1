function New-TestEnvironment([switch]$useTemp)
{
	$testName = [IO.Path]::GetFileNameWithoutExtension($MyInvocation.PSCommandPath);

	$rootDir = $PSScriptRoot;
	for ($i = 0; $i -lt 2; $i++) { $rootDir = Split-Path $rootDir -Parent; }

	$baseDir = &{ if ($useTemp) { return $env:TEMP; } else { return $rootDir; }};
	$testResultsDir = "$baseDir\TestResults\$testName";
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

		$testName = [IO.Path]::GetFileNameWithoutExtension($MyInvocation.PSCommandPath);
		$ext = [IO.Path]::GetExtension($receivedFile);
		$filename = [IO.Path]::GetFileNameWithoutExtension($receivedFile);
		$approvedFile = "$approvalTestsDir\$($testName).$filename.approved$ext";
		if (-not (Test-Path $approvedFile)) { New-Item $approvedFile -ItemType File | Out-Null; }

		$diff = 001;
		try { $diff = Compare-Object (Get-Content $receivedFile) (Get-Content $approvedFile); } catch { $diff = 001; }
		if ($diff -ne $null)
		{
			Write-Host "Copy-Item `"$receivedFile`" `"$approvedFile`";";
			Invoke-Item $receivedFile;
			throw "'$(Split-Path $receivedFile -Leaf)' is not approved.";
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