<#
.SYNOPSIS
This function checks if Git is installed on the current machine.

.DESCRIPTION
This function will check if Git is installed on the this machine. Returns $true if installed false if otherwise.

.EXAMPLE
Assert-GitIsInstalled;
#>
function Assert-GitIsInstalled()
{
	return (&git version | out-string) -match '(?i)(v|ver|version)\s*\d+\.\d+\.\d+';
}