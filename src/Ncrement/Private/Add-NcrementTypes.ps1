<#
#>

foreach ($file in (Get-ChildItem $PSScriptRoot -Filter "*.cs" | Sort-Object { $_.Name } -Descending))
{
	$content = Get-Content $file.FullName | Out-String;
	Add-Type -TypeDefinition $content;
}