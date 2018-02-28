<#
.SYNOPSIS
Loads all the custom types required by this module.
#>

foreach ($file in (Get-ChildItem $PSScriptRoot -Filter "*.cs" | Sort-Object { $_.Name } -Descending))
{
	Add-Type -Path $file.FullName;
}