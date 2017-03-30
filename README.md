# Welcome to the Buildbox
|          |master|development|
|----------|------|-----------|
|**status**|![master]()|![dev](https://acklann.visualstudio.com/_apis/public/build/definitions/86cb9590-1aed-43de-984c-768155a6970f/14/badge)|

----------
Buildbox is a collection of build scripts, modules and tools designed for continuous integration and deployment.

## FTP Operations
The **winscp.psm1** module is used for basic ftp operations. It leverage the [WinSCP](https://winscp.net/eng/index.php) [nuget package](https://www.nuget.org/packages/WinSCP/) to complete all operations.

|Function|Description|
|--------|-----------|
|[New-WinSCPSession](src/Modules/winscp.psm1) |Creates a new WinSCP session.|
|[Get-WinSCPFiles](src/Modules/winscp.psm1)   |Download files from a ftp server.|
|[Send-WinSCPFiles](src/Modules/winscp.psm1)  |Upload files to a ftp server.|
|[Remove-WinSCPFiles](src/Modules/winscp.psm1)|Remove files from a ftp server.|

#### Example 1
```powershell
New-WinSCPSession "host" "userId" "password" | Send-WinSCPFiles -from "C:\site\*" "/-to example.com/wwwroot/";
```
Upload all files within your site's directory to your server.
#### Example 2
```powershell
New-WinSCPSession "host" "userId" "password" | Get-WinSCPFiles -from "/example.com/wwwroot/" -to "C:\file.txt";
```
Downloads the example.com site to a local directory.

## Web Deploy


## Contribute!






