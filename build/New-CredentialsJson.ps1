Param(
	[Parameter(Mandatory)]
	[string]$Server,

	[Parameter(Mandatory)]
	[string]$Username,
	
	[Parameter(Mandatory)]
	[string]$password
)

$content = @"
{
  "ftp":
  {
	"host": "$Server",
	"user": "$Username",
	"password": "$password"
  }
}
"@;
$content | Out-File "$(Split-Path $PSScriptRoot -Parent)\tests\MSTest.Buildbox\credentials.json" -Encoding utf8;
