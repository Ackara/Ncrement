Param(
	[Parameter(Mandatory)]
	[string]$Host,

	[Parameter(Mandatory)]
	[string]$Username,
	
	[Parameter(Mandatory)]
	[string]$password
)

$content = @"
{
  "ftp":
  {
	"host": "$Host",
	"user": "$Username",
	"password": "$password"
  }
}
"@;
$content | Out-File "$(Split-Path $PSScriptRoot -Parent)\tests\Tests.Buildbox\credentials.json" -Encoding utf8;
