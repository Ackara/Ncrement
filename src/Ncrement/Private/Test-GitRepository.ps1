<#
.SYNOPSIS
Determines if the specified location is a git repository.

.PARAMETER Path
The path to test.

.OUTPUTS
[Boolean]

.EXAMPLE
$isRepo = Test-GitRepository;
This example, checks if the current directory is a git repository.

.EXAMPLE
$isRepo = "C:\project\app\app.csproj" Test-GitRepository;
This example, checks if the current file is in a git repository.
#>

function Test-GitRepository
{
	Param(
		[Parameter(ValueFromPipeline)]
		[string]$Path
	)

	if ([string]::IsNullOrEmpty($Path))
	{
		$Path = $PWD;
	}
	elseif (-not (Test-Path $Path))
	{
		return $false;
	}
	elseif (Test-Path $Path -PathType Leaf)
	{
		$Path = Split-Path $Path -Parent;
	}

	try
	{
		Push-Location $Path;
		return (-not ((&git status | Out-String) -match '(?i)not\s+a\s+git\s+repository'));
	}
	finally { Pop-Location; }

	return $false;
}