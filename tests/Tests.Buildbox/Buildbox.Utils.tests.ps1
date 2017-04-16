#
# This is a PowerShell Unit Test file.
# You need a unit test framework such as Pester to run PowerShell Unit tests. 
# You can download Pester from http://go.microsoft.com/fwlink/?LinkID=534084
#

Param ([string]$BuildConfiguration="Debug")
Import-Module "$PSScriptRoot\utils.psm1" -Force;

$rootDir = Get-RootDir;
$module = "$rootDir\src\Buildbox.Utils\buildbox.Utils.psm1";
Import-Module $module -Force;
