$rootDir = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent;
$module = "$rootDir\src\Buildbox.WAWSDeploy\Buildbox.WAWSDeploy.psm1";
Import-Module $module -Force;

# Assign Values
$sampleDir = "$PSScriptRoot\Samples\waws";

Describe "Install-WAWSDeploy" {
    $settings = "$sampleDir\waws.publishsettings";
    "abc" | Out-File $settings;

    Invoke-WAWSDeploy $sampleDir $settings -WhatIf;
    
	It "should install wawsdeploy to the module's directory." {
        $expectedWAWSDeployPath = Get-Item "$(Split-Path $module -Parent)\bin\wawsdeploy" -Filter "*.exe" | Select-Object -ExpandProperty FullName -First 1;
        $expectedWAWSDeployPath | Should Exist;
	}
}