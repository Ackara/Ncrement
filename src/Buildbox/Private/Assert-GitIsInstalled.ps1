function Assert-GitIsInstalled()
{
	<#
	.SYNOPSIS
	This function checks if Git is installed on the current machine.

	.DESCRIPTION
	This function will check if Git is installed on the this machine. Returns $true if installed false if otherwise.

	.EXAMPLE
	Assert-GitIsInstalled;
	#>
	foreach ($path in [System.Environment]::GetEnvironmentVariable("PATH").Split(';'))
	{
		if (Test-Path "$path\git.exe" -PathType Leaf)
		{
		    return $true;
		}
	}

	return $false;
}