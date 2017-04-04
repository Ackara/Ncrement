$Script:Bin = "$PSScriptRoot\bin\winscp";

function Install-WinSCP()
{
	<#
	.SYNOPSIS
	Downloads the WinSCP .NET assembly.

	.DESCRIPTION
	This cmdlet will download the WinSCP .NET assembly from nuget.org to the module's location
	if they do not already exist. The other cmdlets in the module need these binaries
	in order to work.

	.EXAMPLE
	Install-WinSCP
	Downloads the assembly.
	#>

	$version = "5.9.4";
	$winscpDLL = "$Script:Bin\WinSCPnet.dll";
	if (-not (Test-Path $winscpDLL -PathType Leaf))
	{
		$nupkg = "$env:TEMP\winscp$version.zip";
		try
		{
			if (-not (Test-Path $nupkg -PathType Leaf))
			{
				Write-Verbose "downloading winscp.nupkg ...";
				if (-not (Test-Path "$Script:Bin" -PathType Container)) { New-Item "$Script:Bin" -ItemType Directory | Out-Null; }
				Invoke-WebRequest "https://www.nuget.org/api/v2/package/WinSCP/$version" -OutFile $nupkg;
			}
			Expand-Archive $nupkg $Script:Bin;

			# Remove all unecessary files.
			Move-Item "$Script:Bin\lib\WinSCPnet.dll" $Script:Bin;
			Move-Item "$Script:Bin\content\WinSCP.exe" $Script:Bin;
			Get-ChildItem $Script:Bin -Recurse -Exclude @("WinSCPnet.dll", "WinSCP.exe") | Remove-Item -Recurse -Force;
		}
		finally { if (Test-Path $nupkg -PathType Leaf) { Remove-Item $nupkg | Out-Null; } }
	}
	Import-Module $winscpDLL;
}

function New-WinSCPSession()
{
	<#
	.SYNOPSIS
	Creates a [WinSCP.SessionOptions] object.

	.DESCRIPTION
	This cmdlet creates a [WinSCP.SessionOptions] object. It stores the connection
	details needed to open a connection to the FTP server. The session options is
	required by all the other cmdlets in this module so its a good idea to store it
	in a variable.

	.PARAMETER HostName
	The server's addreess.

	.PARAMETER Username
	Your account user id.

	.PARAMETER Password
	Your account password.

	.PARAMETER Protocol
	The connection protocol. Ftp is the only protocol support at the moment.

	.PARAMETER  Port
	The server's FTP port number.

	.INPUTS
	User credentials.

	.OUTPUTS
	WinSCP.SessionOptions

	.EXAMPLE
	$session = New-WinSCPSession "your_server_address" "your_username" "your_password";
	This example creates a session variable that can be used to open a FTP connection.

	.LINK
	https://github.com/Ackara/Buildbox
	#>

	[CmdletBinding()]
	Param(
		[Alias("server", "host", "address", "ip", "h")]
		[Parameter(Mandatory=$true, Position=1)]
		[ValidateNotNullOrEmpty()]
		[string]$HostName,

		[Alias("userId", "user", "u")]
		[Parameter(Mandatory=$true, Position=2)]
		[ValidateNotNullOrEmpty()]
		[string]$Username,

		[Alias("pwd", "p")]
		[Parameter(Mandatory=$true, Position=3)]
		[ValidateNotNullOrEmpty()]
		[string]$Password,

		[ValidateSet("Ftp", "Sftp", "Scp", "Webdav")]
		[string]$Protocol = "Ftp",

		[int]$Port = 21
	)

	Install-WinSCP;

	$sessionOptions = New-Object WinSCP.SessionOptions;
	$sessionOptions.Protocol = ([Enum]::Parse([WinSCP.Protocol], $Protocol));
	$sessionOptions.HostName = $HostName;
	$sessionOptions.UserName = $Username;
	$sessionOptions.Password = $Password;
	$sessionOptions.PortNumber = $Port;

	return $sessionOptions;
}

function Get-WinSCPFiles()
{
	<#
	.SYSNOPSIS
	Download files from a designated ftp server.

	.PARAMETER SessionOptions
	The [WinSCP.SessionOptions] object that stores the connection details.

	.PARAMETER RemotePath
	The path to the files you want to download.

	.PARAMETER LocalPath
	The path to put the downloaded files.

	.INPUTS
	WinSCP.SessionOptions

	.OUTPUTS
	WinSCP.TransferOperationResult

	.EXAMPLE
	New-WinSCPSession "host" "user" "password" | Get-WinSCPFiles "/example.com/wwwroot/" "C:\file.txt";
	This example downloads a file from example.com using the Ftp protocol.

	.LINK
	New-WinSCPSession

	.LINK
	https://github.com/Ackara/Buildbox
	#>

	[CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
	Param (
		[ValidateNotNull()]
		[Parameter(Mandatory=$true, ValueFromPipeline=$true)]
		[WinSCP.SessionOptions]$SessionOptions,

		[Alias("from", "src", "source")]
		[Parameter(Mandatory=$true, Position=1)]
		[ValidateNotNullOrEmpty()]
		[string]$RemotePath,

		[Alias("to", "dest", "destination")]
		[Parameter(Mandatory=$true, Position=2)]
		[ValidateNotNullOrEmpty()]
		[string]$LocalPath,

		[switch]$Overwrite
	)

	PROCESS
	{
		$session = New-Object WinSCP.Session;

		try
		{
			$session.Open($SessionOptions);
			Write-Verbose "Opened a connection to $($SessionOptions.HostName).";

			if ($PSCmdlet.ShouldProcess("server: $($SessionOptions.HostName), path: $RemotePath"))
			{
				$overwriteMode = ( & { if ($Overwrite) { return [WinSCP.OverwriteMode]::Overwrite } else { return [WinSCP.OverwriteMode]::Resume } });
				$transferOptions = New-Object WinSCP.TransferOptions;
				$transferOptions.TransferMode = [WinSCP.TransferMode]::Binary;
				$transferOptions.OverwriteMode = $overwriteMode;
				$results = $session.GetFiles($RemotePath, $LocalPath, $false, $transferOptions);

				foreach ($transfer in $results.Transfers)
				{
					if ($transfer.Error)
					{ Write-Warning "$($transfer.Error.Message)."; }
					else
					{ Write-Verbose "Downloaded $($transfer.FileName) to $($transfer.Destination)."; }
				}

				return $results;
			}
		}
		finally
		{
			$session.Dispose();
			Write-Verbose "Closed connection to $($SessionOptions.HostName).";
		}
	}
}

function Send-WinSCPFiles()
{
	<#
	.SYSNOPSIS
	Uploads files to a designated ftp server.

	.PARAMETER SessionOptions
	The [WinSCP.SessionOptions] object that stores the connection details.

	.PARAMETER LocalPath
	The path to the files you want to upload.

	.PARAMETER RemotePath
	The path to where your files will to uploaded to.

	.INPUTS
	WinSCP.SessionOptions

	.OUTPUTS
	WinSCP.TransferOperationResult

	.EXAMPLE
	 New-WinSCPSession "host" "user" "password" | Send-WinSCPFiles "C:\file.txt" "/example.com/wwwroot/";
	This example uploads a file to example.com using the Ftp protocol.

	.LINK
	New-WinSCPSession

	.LINK
	https://github.com/Ackara/Buildbox
	#>

	[CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
	Param (
		[Alias("session")]
		[Parameter(Mandatory=$true, ValueFromPipeline=$true)]
		[ValidateNotNull()]
		[WinSCP.SessionOptions]$SessionOptions,

		[Alias("from", "src", "source", "path")]
		[Parameter(Mandatory=$true, Position=1)]
		[string]$LocalPath,

		[Alias("to", "dest", "destination")]
		[Parameter(Mandatory=$true, Position=2)]
		[string]$RemotePath,

		[switch]$Overwrite
	)

	PROCESS
	{
		$session = New-Object WinSCP.Session;

		try
		{
			$session.Open($SessionOptions);
			Write-Verbose "Opened a connection to $($SessionOptions.HostName).";

			if ($PSCmdlet.ShouldProcess("'$LocalPath' >> { server: $($SessionOptions.HostName), path: $RemotePath }"))
			{
				$overwriteMode = ( & { if ($Overwrite) { return [WinSCP.OverwriteMode]::Overwrite } else { return [WinSCP.OverwriteMode]::Resume } });
				$transferOptions = New-Object WinSCP.TransferOptions;
				$transferOptions.TransferMode = [WinSCP.TransferMode]::Binary;
				$transferOptions.OverwriteMode = $overwriteMode;
				$results = $session.PutFiles($LocalPath, $RemotePath, $false, $transferOptions);

				foreach ($transfer in $results.Transfers)
				{
					if ($transfer.Error)
					{ Write-Warning "$($transfer.Error.Message)."; }
					else
					{ Write-Verbose "Uploaded $($transfer.FileName) to $($transfer.Destination)."; }
				}

				return $results;
			}
		}
		finally
		{
			$session.Dispose();
			Write-Verbose "Closed connection to $($SessionOptions.HostName).";
		}
	}
}

function Remove-WinSCPFiles()
{
	<#
	.SYNOPSIS
	Delete files from a designated ftp server.

	.DESCRIPTION
	This cmdlet removes files from a Ftp server.

	.PARAMETER SessionOptions
	The [WinSCP.SessionOptions] object that stores the connection details.

	.PARAMETER RemotePath
	The path to the files you want to remove.

	.INPUTS
	WinSCP.SessionOptions

	.OUTPUTS
	WinSCP.RemovalOperationResult

	.EXAMPLE
	New-WinSCPSession "host" "user" "password" | Remove-WinSCPFiles "/example.com/wwwroot/file_to_delete.txt";
	This example removes a file from example.com using the Ftp protocol.

	.EXAMPLE
	New-WinSCPSession "host" "user" "password" | Remove-WinSCPFiles "/example.com/wwwroot/file_to_delete.txt" -Confim:$false;
	This example removes a file from example.com using the Ftp protocol without the confirmation prompt.

	.LINK
	New-WinSCPSession

	.LINK
	https://github.com/Ackara/Buildbox
	#>

	[CmdletBinding(SupportsShouldProcess, ConfirmImpact = "High")]
	Param(
	[Parameter(Mandatory=$true, ValueFromPipeline=$true)]
	[WinSCP.SessionOptions]$SessionOptions,

	[Alias("path")]
	[Parameter(Mandatory=$true, Position=1)]
	[string]$RemotePath
	)

	PROCESS
	{
		$session = New-Object WinSCP.Session;

		try
		{
			$session.Open($SessionOptions);
			Write-Verbose "Opened a connection to $($SessionOptions.HostName).";

			if ($PSCmdlet.ShouldProcess("server: $($SessionOptions.HostName), path: $RemotePath"))
			{
				$results = $session.RemoveFiles($RemotePath);
				foreach($item in $results.Removals)
				{
					if ($item.Error)
					{ Write-Warning $item.Error.Message; }
					else
					{ Write-Verbose "Deleted $($item.FileName)."; }
				}

				return $results;
			}
		}
		finally
		{
			$session.Dispose();
			Write-Verbose "Closed connection to $($SessionOptions.HostName).";
		}
	}
}

Export-ModuleMember -Function @("New-*", "Send-*", "Get-*", "Remove-*");