# Import Module
$srcDir = Split-Path $PSScriptRoot -Parent;
$module = "$srcDir\Modules\winscp.psm1";
Import-Module $module -Force;

# Assign Values
$sampleDir = "$PSScriptRoot\Samples\winscp";
$sampleFile = "$sampleDir\buildbox-file1.txt";
$serverInfo = (Get-Content "$PSScriptRoot\credentials.json" | Out-String | ConvertFrom-Json).ftp;

Describe "New-WinSCPSession" {
    Context "FTP" {
        $sut = New-WinSCPSession -HostName $serverInfo.host -Username $serverInfo.user -Password $serverInfo.password;

        It "should return a object of type [WinSCP.SessionOptions]." {
            $sut | Should BeOfType  WinSCP.SessionOptions;
        }

        It "should return a fully initialized object." {
            $sut.HostName | Should Be $serverInfo.host;
            $sut.UserName | Should Be $serverInfo.user;
            $sut.Password | Should Be $serverInfo.password;
            $sut.PortNumber | Should Be 21;
            $sut.Protocol | Should Be "Ftp";
        }

        It "should download winscp binaries at the modules location." {
            $moduleDir = Split-Path $module -Parent;
            $exeExist = (Test-Path "$moduleDir\bin\winscp\WinSCP.exe" -PathType Leaf);
            $dllExist = (Test-Path "$moduleDir\bin\winscp\WinSCPnet.dll" -PathType Leaf);

            $exeExist | Should Be $true;
            $dllExist | Should Be $true;
        }
    }
}

Describe "Get-WinSCPFiles" {
    $remoteFiles = "/$($serverInfo.host)/wwwroot/miscellaneous/buildbox/*";
    $destination = "$PSScriptRoot\bin\downloads";

    Context "FTP" {
        $sut = New-WinSCPSession -HostName $serverInfo.host -Username $serverInfo.user -Password $serverInfo.password;
        if (Test-Path $destination -PathType Container) { Remove-Item $destination -Recurse -Force; }

        $results = ($sut | Get-WinSCPFiles $remoteFiles "$destination\*");

        It "should return a object of type [WinSCP.TransferOperationResult]." {
            $results | Should BeOfType WinSCP.TransferOperationResult;
            $results.IsSuccess | Should Be $true;
        }

        It "should download all sample files from the designated ftp server directory." {
            $totalFiles = (Get-ChildItem $destination -Filter "*.txt" | Measure-Object).Count;
            $totalFiles | Should BeGreaterThan 1;
        }
    }
}

Describe "Remove-WinSCPFiles" {
    $remotePath = "/$($serverInfo.host)/wwwroot/miscellaneous/buildbox/buildbox-file1.txt";

    Context "FTP" {
        $sut = New-WinSCPSession -HostName $serverInfo.host -Username $serverInfo.user -Password $serverInfo.password;
        $results = ($sut | Remove-WinSCPFiles $remotePath -Confirm:$false);

        It "should return an object of type [WinSCP.RemovalOperationResult]." {
            $results | Should BeOfType "WinSCP.RemovalOperationResult";
        }

        It "should remove files from the designated ftp server." {
            $results.IsSuccess | Should Be $true;
        }
    }
}

Describe "Send-WinSCPFiles" {
    $destination = "/$($serverInfo.host)/wwwroot/miscellaneous/buildbox/*";

    Context "FTP" {
        $sut = New-WinSCPSession -HostName $serverInfo.host -Username $serverInfo.user -Password $serverInfo.password;
        $results = ($sut | Send-WinSCPFiles $sampleFile $destination);

        It "should return an object of type [TransferOperationResult]." {
            $results | Should BeOfType "WinSCP.TransferOperationResult";
        }

        It "should upload files to the designated ftp server." {
            $results.IsSuccess | Should Be $true;
        }
    }
}

if (Get-Module winscp) { Remove-Module winscp; }