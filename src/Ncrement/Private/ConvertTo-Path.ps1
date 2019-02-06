function ConvertTo-Path
{
	Param([Parameter(Mandatory)]$InputObject)

	[string]$path = $null;
	if ($InputObject | Get-Member "FullName") { $path = $InputObject.FullName; }
	try { if (Test-Path $InputObject -PathType Leaf) { $path = $InputObject; } } catch { }

	return $path;
}