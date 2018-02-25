<#
.SYSNOPSIS
This cmdlet outputs a line seperator to the console.

.PARAMETER Title
An optional string of text to embed into the

.PARAMETER Length
The lenght of the line. (Default: 70).
#>

function Write-LineBreak([string]$Title = "", [int]$length = 70)
{
	$line = [string]::Join('', [System.Linq.Enumerable]::Repeat('-', $length));
	if (-not [String]::IsNullOrEmpty($Title))
	{
		$line = $line.Insert(4, " $Title ");
		if ($line.Length -gt $length) { $line = $line.Substring(0, $length); }
	}

	Write-Host ''; Write-Host $line; Write-Host '';
}
