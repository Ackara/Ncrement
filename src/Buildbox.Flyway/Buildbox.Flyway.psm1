$Script:flyway = "$PSScriptRoot\bin\flyway*\flyway.cmd";

function Install-Flyway([string]$Version = "4.1.2")
{
	<#
	.SYNOPSIS
	Download the flyway toolset to the module's location.

	.PARAMETER Version
	The version number.

	.INPUTS
	None

	.OUTPUTS
	None

	.EXAMPLE
	Install-Flyway
	In this example, the flyway toolset is downloaded from 'https://flywaydb.org/' to the module's current location.

	.LINK
	https://flywaydb.org/getstarted

	.LINK
	https://github.com/Ackara/Buildbox
	#>

	if (-not (Test-Path $Script:flyway -PathType Leaf))
	{
		$zip = "$PSScriptRoot\flyway.zip";
		try
		{
			if (-not (Test-Path $zip -PathType Leaf))
			{
				Write-Verbose "downloading flyway ...";
				Invoke-WebRequest "https://repo1.maven.org/maven2/org/flywaydb/flyway-commandline/$Version/flyway-commandline-$Version-windows-x64.zip" -OutFile $zip;
				Write-Verbose "flyway downloaded."
			}

			Expand-Archive $zip "$PSScriptRoot\bin";
		}
		finally
		{
			if (Test-Path $zip -PathType Leaf) { Remove-Item $zip -Force; }
		}
	}

	$Script:flyway = Get-Item $Script:flyway | Select-Object -ExpandProperty FullName -First 1;
	return $Script:flyway;
}

function Copy-FlywayConfig()
{
	<#
	.SYNOPSIS
	Copy the default 'flyway.conf' file to a new location.

	.DESCRIPTION
	This function will copy the default 'flyway.conf' file (default: filesystem:<<INSTALL-DIR>>/conf/) to a new location.
	If the parent directory of the new location has not yet been created; it will be.

	.PARAMETER Destination
	The new file path.

	.OUTPUTS
	None

	.EXAMPLE
	Copy-FlywayConfig "C:\project\settings\flyway.conf";
	In this example, the default 'flyway.config' file is copied to the specified location.

	.LINK
	https://flywaydb.org/

	.LINK
	https://github.com/Ackara/Buildbox
	#>
	Param(
		[Parameter(Mandatory)]
		[string]$Destination
	)

	$config = "$(Split-Path $Script:flyway -Parent)\conf\flyway.conf";

	if (Test-Path $Destination -PathType Container)
	{
		Copy-Item $Script:flyway "$Destination\$(Split-Path $Script:flyway -Leaf)" -Force;
	}
	else
	{
		$parentDir = Split-Path $Destination -Parent;
		if (-not (Test-Path $parentDir -PathType Container)) { New-Item -ItemType Directory | Out-Null; }
		Copy-Item -Path $config -Destination $Destination -Force;
	}
}

function Edit-FlywayConfig()
{
	<#
	.SYNOPSIS
	Change the values within a 'flyway.conf' file.

	.DESCRIPTION
	This function helps you overwrite values within an existing 'flyway.conf' file.
	If the path is not specified the default '.conf' file will be used.

	.PARAMETER Path
	The path to the conf file.
	
	.PARAMETER Url
	Set the flyway.url property.

	.PARAMETER User
	Set the flyway.user property.

	.PARAMETER Password
	Set the flyway.password property.

	.PARAMETER Locations
	Set the flyway.locations property.
	
	.OUTPUTS
	None

	.EXAMPLE
	Edit-FlywayConfg -User "ackara";
	In this example, the 'flyway.user' property within the default '.config' file is set to 'ackara'.

	.EXAMPLE
	Edit-FlywayConfig -Path "C:\flyway\conf\flyway.conf" -User "ackara" -Password "password1";
	In this example, the user and password properties within the specified '.conf' file is overwritten.

	.LINK
	https://flywaydb.org/

	.LINK
	https://github.com/Ackara/Buildbox
	#>

	[CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
	Param(
		[string]$Path,
		[string]$Url,
		[string]$User,
		[string]$Password,
		[string]$Locations
	)

	if (([String]::IsNullOrEmpty($Path)) -or (-not (Test-Path $Path -PathType Leaf)))
	{
		Write-Verbose "cannot find '$Path', the default flyway.conf file will be used.";
		$Path = Get-Item $Script:flyway | Select-Object -ExpandProperty FullName | Split-Path -Parent;
		$Path = "$Path\conf\flyway.conf";
	}

	$content = (Get-Content $Path | Out-String).Trim();

	$map = @{"url"=$Url;"user"=$User;"password"=$Password;"locations"="$Locations"};
	foreach ($key in $map.Keys)
	{
		$value = $map[$key];
		if (-not [string]::IsNullOrEmpty($value))
		{
			if ($key -eq "locations") { $value = "filesystem:$value"; }
			$content = $content -replace "(#\s*)?flyway\.$key=.*", "flyway.$key=$value";
			Write-Verbose "setting flyway.$key to '$value'.";
		}
	}

	if ($PSCmdlet.ShouldProcess("$Path"))
	{ 
		$content | Out-File $Path -Encoding utf8;
		Write-Verbose "'$Path' was updated.";
	}
}

function Invoke-Flyway()
{
	<#
	.SYNOPSIS
	Execute a flyway command.

	.DESCRIPTION
	This function executes a flyway command and provide parameters to overwrite some settings when called.
	If flyway has not yet been installed, it will be done automatically.

	.PARAMETER Action
	The flyway command.
	
	.PARAMETER ConfigFile
	The path of 'flyway.conf' file to use.
	
	.PARAMETER Url
	The jdbc url to use to connect to the database.
	
	.PARAMETER User
	The user to use to connect to the database.
	
	.PARAMETER Password
	The password to use to connect to the database.
	
	.PARAMETER Locations
	Comma-separated list of locations to scan recursively for migrations.

	.PARAMETER Credential
	The username and password for the connection, if not specified the User and Password fields are used instead.
	
	.OUTPUTS
	None

	.EXAMPLE
	Invoke-Flyway info -Url "jdbc:mysql://localhost/buildbox" -Locations "C:\project\migrations";
	In this example, the 'info' command is invoked while Overwriting 'url' and 'locations' properties in the default config file.

	.EXAMPLE
	Invoke-Flyway migrate -ConfigFile "C:\project\settings\flyway.conf";
	In this example, the 'migrate' command is invoked using the options assigned in the specified config file.
	
	.LINK
	https://flywaydb.org
	
	.LINK
	https://github.com/Ackara/Buildbox

	#>
	[CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
	Param(
		[Parameter(Mandatory, Position=1)]
		[ValidateSet("migrate", "clean", "info", "validate", "baseline", "repair")]
		[string]$Action,

		[Parameter(Position=2)]
		[string]$ConfigFile,

		[string]$Url,
		[string]$Username,
		[string]$Password,
		[string]$Locations,
		[PSCredential]$Credential
	)

	Install-Flyway;

	if ($Credential)
	{
		$Username = $Credential.UserName;
		$Password = $Credential.GetNetworkCredential().Password;
	}

	$map = @{
				"url"=$Url;
				"user"=$Username;
				"password"=$Password;
				"locations"=$Locations;
			};

	$index = 0;
	$options = @();
	if (-not [String]::IsNullOrEmpty($ConfigFile))
	{ 
		$options += "-configFile=$ConfigFile"; 
	}
	else
	{
		foreach ($key in $map.Keys)
		{
			$value = $map[$key];
			if (-not [String]::IsNullOrEmpty($value))
			{
				if ($key -eq "locations")
				{ $value = "filesystem:$value"; }
				
				$options += ("-$key=$value");
			}
		}
	}
	
	#Write-Host "> $Action $options";
	if ($PSCmdlet.ShouldProcess("$Action $options"))
	{
		return [FlywayResults]::new((& $Script:flyway $Action $options | Out-String));
	}
}

#region Classes

Class FlywayResults
{
	FlywayResults([string]$output)
	{
		if (-not [String]::IsNullOrEmpty($output))
		{
			$this.RawOutput = $output;
			$regex = [Regex]::new('(?i)\s(no migrations found|pending)\s');

			if ($regex.IsMatch($output))
			{
				switch ($regex.Match($output).Value.Trim().ToLower())
				{
					default { $this.State = [FlywayState]::None; }

					"pending" { $this.State = [FlywayState]::Pending; }
					"no migrations found" { $this.State = [FlywayState]::Empty; }
				}
			}
		}
	}

	[FlywayState]$State
	[string]$RawOutput = ""
}

Enum FlywayState
{
	None
	Pending
	Empty
}

#endregion