Import-Module "C:\Users\Ackeem\Projects\Buildbox\tools\Pester\3.4.6\Pester.psm1" -Force;

Invoke-Pester -Script "$PSScriptRoot\Tests\Update-ProjectManifests.tests.ps1";