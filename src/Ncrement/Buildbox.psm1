if (-not (Test-Path "$PSScriptRoot\bin" -PathType Container)) { New-Item "$PSScriptRoot\bin" -ItemType Directory | Out-Null; }
$public  = @(Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1" -ErrorAction SilentlyContinue);
$private = @(Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" -ErrorAction SilentlyContinue);

foreach($import in @($public + $private))
{
	try
	{
	    . $import.FullName
	}
	catch
	{
	    Write-Error -Message "Failed to import function $($import.fullname): $_"
	}
}

Export-ModuleMember -Function $public.Basename;