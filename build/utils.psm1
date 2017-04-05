
function Write-BreakLine([string]$Title)
{
    $line = "`n----------------------------------------------------------------------";
	$limit = $line.Length;
	if (-not [String]::IsNullOrEmpty($Title))
	{
		$line = $line.Insert(4, " $Title ");
		if ($line.Length -gt $limit) { $line = $line.Substring(0, $limit); }
	}

	Write-Host $line;
	Write-Host "";
}