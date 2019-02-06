function New-TestEnvironment([string]$testName = "", [switch]$Data, [switch]$Git)
{
	if ([string]::IsNullOrEmpty($testName))
	{
		$testName = [IO.Path]::GetFileNameWithoutExtension($MyInvocation.PSCommandPath).Replace(".tests", "");
	}

	$testDir = Join-Path $env:TEMP "ncrement\$testName";
	$testFiles = Join-Path $testDir "sample-data";

	if (Test-Path $testDir) { Remove-Item $testDir -Recurse -Force; }
	if ($Data) { Copy-Item "$PSScriptRoot\sample-data\" -Destination $testFiles -Recurse; }
	else { $testFiles = Join-Path $PSScriptRoot "sample-data"; }

	if ($Git)
	{
		try
		{
			Push-Location $testDir;
			&git init;
			&git add .;
			&git commit -m "intia commit" | Out-Null;
			&git branch dev | Out-Null;
			&git checkout dev | Out-Null;
		}
		finally { Pop-Location; }
	}

	return New-Object PSObject -Property @{
		"TestName"=$testName;
		"TestDir"=$testDir;
		"SampleDir"=$testFiles;
	};
}

function Approve-File([Parameter(ValueFromPipeline)][string]$receivedFile)
{
	$passed = $true;
	if (Test-Path $receivedFile)
	{
		if ($receivedFile.EndsWith(".psd1"))
		{
			$contents = Get-Content $receivedFile | Out-String;
			$contents -replace 'Generated\s+on:\s+\d+/\d+/\d+', "Generated" | Out-File $receivedFile -Encoding utf8;
		}

		$approvalTestsDir = Join-Path $PSScriptRoot "approved-results";
		if (-not (Test-Path $approvalTestsDir)) { New-Item $approvalTestsDir -ItemType Directory | Out-Null; }

		$ext = [IO.Path]::GetExtension($receivedFile);
		$filename = [IO.Path]::GetFileNameWithoutExtension($receivedFile);
		$approvedFile = Join-Path $approvalTestsDir "$filename.approved$ext";
		if (-not (Test-Path $approvedFile)) { New-Item $approvedFile -ItemType File | Out-Null; }

		$diff = 001;
		try { $diff = Compare-Object (Get-Content $receivedFile) (Get-Content $approvedFile); } catch { $diff = 001; }
		if ($diff -ne $null)
		{
			$passed = $false;
			#Write-Host "Copy-Item `"$receivedFile`" `"$approvedFile`";";

			$bc4 = "C:\Program Files\Beyond Compare 4\BCompare.exe";
			if (Test-Path $bc4)
			{
				&$bc4 $receivedFile $approvedFile;
			}
			else
			{
				Invoke-Item $receivedFile;
			}
			throw "'$(Split-Path $receivedFile -Leaf)' was not approved.";
		}
	}
	else { throw "Could not find the recieved file at '$receivedFile'." }
	return $passed;
}

function Approve-Results([Parameter(ValueFromPipeline)]$result, [string]$testName = "")
{
	if ([string]::IsNullOrEmpty($testName))
	{
		$testName = [IO.Path]::GetFileName($MyInvocation.PSCommandPath).Replace(".tests", "");
	}
	$receivedFile = Join-Path $env:TEMP "ncrement\Results\$testName";

	$dir = Split-Path $receivedFile -Parent;
	if (-not (Test-Path $dir)) { New-Item $dir -ItemType Directory | Out-Null; }
	$result | Out-File $receivedFile -Encoding utf8 -Force;

	return Approve-File $receivedFile;
}

Get-Item "$(Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)\src\*\*.psd1" | Import-Module -Force;