Join-Path $PSScriptRoot "*.psm1" | Get-Item | Import-Module -Force;

Describe "Help" {
	$context = New-TestEnvironment "convert-ver1";
	$manifest = Join-Path $context.SampleDir "manifest.json" | Get-Item;

	It "ConvertTo-NcrementNumber" {
		#help ConvertTo-NcrementVersionNumber -Detailed | Write-Host;
	}

	It "Step-NcrementVersionNumber" {
		#help Step-NcrementVersionNumber -Detailed | Write-Host;
	}

	It "Update-NcrementProjectFile" {
		#help Update-NcrementProjectFile -Detailed | Write-Host;
	}
}