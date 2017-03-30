# Buildbox
|          |master|development|
|----------|------|-----------|
|**status**|![master]()|![dev](https://acklann.visualstudio.com/_apis/public/build/definitions/86cb9590-1aed-43de-984c-768155a6970f/14/badge)|

----------
Buildbox is a collection of build scripts, modules and tools designed for continuous integration and deployment.

## FTP Operations
The **winscp.psm1** module is used for basic ftp operations. It leverage the [WinSCP](https://winscp.net/eng/index.php) [nuget package](https://www.nuget.org/packages/WinSCP/) to complete all operations.



### Funtions List
|Function|Description|
|-------|-----------|
|[New-WinSCPSession](src/Modules/winscp.psm1)|Creates a new WinSCP session.|
|**Get-WinSCPFiles**|Download files from a ftp server.|
|**Send-WinSCPFiles**|Upload files to a ftp server.|
|**Remove-WinSCPFiles**|Remove files from a ftp server.|




