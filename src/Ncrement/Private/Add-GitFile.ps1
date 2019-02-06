function Add-GitFile
{
	[CmdletBinding(ConfirmImpact = "Medium", SupportsShouldProcess)]
	Param(
		[Parameter(ValueFromPipeline)]
		$InputObject,

		[switch]$Commit
	)

	if ($InputObject)
	{
		$path = ConvertTo-Path $InputObject;
		if ($Commit -and ($path) -and (Test-Path $path -PathType Leaf) -and (Test-Git))
		{
			if ($PSCmdlet.ShouldProcess($InputObject, "git-add"))
			{
				try
				{
					Split-Path $path -Parent | Push-Location;
					&git add $path | Out-Null;
					Write-Verbose "Staged '$path'.";
					return $path;
				}
				finally { Pop-Location; }
			}
			else { return $path; }
		}
	}

	return $false;
}