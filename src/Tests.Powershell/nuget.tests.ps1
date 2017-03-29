$srcDir = Split-Path $PSScriptRoot -Parent;
$sampleDir = "$PSScriptRoot\Samples\nuget";
$module = "$srcDir\Modules\nuget.psm1";
Import-Module $module -Force;

Describe "Install-NuGet" {
    
    #Install-NuGet

    Context "nuget.exe exist" {
        $nuget = 
        It "should not download nuget.exe when the 'overwrite' switch is not set." {
            
        }

        It "should " {
        }
    }

    Context "nuget.exe do not exist" {
        It "should download nuget.exe." {
        }
    }
}