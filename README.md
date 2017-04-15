# Welcome to the Buildbox
|          |master|development|
|----------|------|-----------|
|**status**|![master](https://acklann.visualstudio.com/_apis/public/build/definitions/86cb9590-1aed-43de-984c-768155a6970f/17/badge)|![dev](https://acklann.visualstudio.com/_apis/public/build/definitions/86cb9590-1aed-43de-984c-768155a6970f/14/badge)|

----------
Buildbox is a collection of scripts, modules and tools designed for continuous integration and deployment. The goal for each script is to reduce the number of steps required to perform common operations; with little to no configurations required.

## FTP Operations
The **[winscp.psm1](src/Modules/winscp.psm1)** module is used for basic ftp operations. It leverage the [WinSCP](https://winscp.net/eng/index.php) [nuget package](https://www.nuget.org/packages/WinSCP/) to complete all operations.

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
In this example, `C:\site` is uploaded to the *example.com* `wwwrooot/` folder.
#### Example 2
```powershell
New-WinSCPSession "host" "userId" "password" | Get-WinSCPFiles -from "/example.com/wwwroot/" -to "C:\file.txt";
```
In this example, Downloads the example.com site to a local directory.

## Publish Website (using WebDeploy)
Use the **[Invoke-WAWSDeploy.ps1](/src/Scripts/Invoke-WAWSDeploy.ps1)** script to publish a website to azure or any server where WebDeploy is enabled. The script uses the [WAWSDeploy](https://github.com/davidebbo/WAWSDeploy) project to perform it's operation.

|Args|Description|
|----|-----------|
|**Site**|The folder or `.zip` file containing the site.|
|**PublishSettings**|the `.PublishSettings` file.|
|Password|The server web deploy password.|
|DeleteExistingFiles|Remove all files from the server before publishing.|
|AppOffline|Takes the site offline before publishing the site.|

#### Exampe 1
```powershell
> .\Invoke-WAWSDeploy.ps1 "C:\yoursite" "yoursite.com.publishsettings"
```
Publishes a site with the bare minimum arguments passed.

#### Example 2
```powershell
> .\Invoke-WAWSDeploy.ps1 -Site "C:\mysite" -Settings "example.com.publishsettings" -Password "p@55w0rd" -DeleteExistingFiles -AppOffline
```
Publishes a clean copy of the site to the server.

## Contribute!
## Share the love
:star: this repository and tell your friends if you find it useful in anyway.
