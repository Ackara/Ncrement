function New-TestEnviroment()
{
	$rootDir = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent);
	$testResultDir = "$rootDir\TestResults\pester-$((Get-Date).Ticks)";
	$module = Get-Item "$rootDir\src\Buildbox\Buildbox.psd1";
	$downloadDir = "$rootDir\TestResults\downloads";
	
	# Copy TestData folder $testDataDir path.
	$testDataDir = "$testResultDir\TestData";
	Copy-Item "$(Split-Path $PSScriptRoot -Parent)\TestData" -Destination "$testResultDir\TestData" -Recurse -Force;

	foreach ($dir in @($testResultDir, $downloadDir))
	{
		if (-not (Test-Path $dir -PathType Container))
		{
			New-Item $dir -ItemType Directory | Out-Null;
		}
	}

	return New-Object PSObject -Property @{
		"TestResultsDir"=$testResultDir;
		"TestDataDir"=$testDataDir;
		"DownloadDir"=$downloadDir;
		"ProjectDir"=$rootDir;
		"Module"=$module;
	};
}

function Approve-File([string]$ReceivedFile, [string]$TestName)
{
	if (Test-Path $ReceivedFile -PathType Leaf)
	{
		$approvalsDir = "$PSScriptRoot\ApprovalTests";
		if (-not (Test-Path $approvalsDir -PathType Container)) { New-Item $approvalsDir -ItemType Directory | Out-Null; }

		$extension = [IO.Path]::GetExtension($ReceivedFile);
		$approvalFile = "$approvalsDir\$TestName.approved$extension";
		if (-not (Test-Path $approvalFile -PathType Leaf)) { New-Item $approvalFile -ItemType File | Out-Null; }

		try
		{
			$diff = Compare-Object $(Get-Content $ReceivedFile) $(Get-Content $approvalFile);
			if ($diff) { throw "files don't match"; } else { return $true; }
		}
		catch
		{
			Write-Host "COPY /Y `"$ReceivedFile`" `"$approvalFile`"";
			Invoke-Item $ReceivedFile;
			return $false;
		}
	}
	else { throw "could not find receieved file at '$ReceivedFile'."; }
}
