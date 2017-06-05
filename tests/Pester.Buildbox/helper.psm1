function Approve-File()
{
	Param(
		[string]$Path,
		[string]$TestName
	)

	$approvalsDir = "$PSScriptRoot\ApprovalTests";
	if (-not (Test-Path $approvalsDir -PathType Container)) { New-Item $approvalsDir -ItemType Directory | Out-Null; }

	$extension = [IO.Path]::GetExtension($Path);
	$approvalFile = "$approvalsDir\$TestName.approved$extension";
	if (-not (Test-Path $approvalFile -PathType Leaf)) { New-Item $approvalFile -ItemType File | Out-Null; }

	try
	{
		$diff = Compare-Object $(Get-Content $Path) $(Get-Content $approvalFile);
		if ($diff) { throw "files don't match"; } else { return $true; }
	}
	catch
	{
		Write-Host "COPY /Y `"$Path`" `"$approvalFile`"";
		& "$env:ProgramFiles\Notepad++\notepad++.exe" $Path;
		return $false;
	}
}

function Get-RootDir()
{
	return Split-Path (Split-Path $PSScriptRoot -Parent) -Parent;
}

function New-TestResultsDir($name)
{
	$rootDir = Get-RootDir;
	$testResultsDir = "$rootDir\TestResults\pester-$((Get-Date).ToString('yyyyMMddHHmmss'))\$name";
	if (-not (Test-Path $testResultsDir -PathType Container)) { New-Item $testResultsDir -ItemType Directory | Out-Null; }
	return $testResultsDir;
}
