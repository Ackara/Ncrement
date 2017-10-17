function Edit-FlywayConf()
{
	<#
	.SYNOPSIS
	This cmdlet edits a 'flyway.conf' file.

	.DESCRIPTION
	This cmdlet will edit a 'flyway.conf' file using the arguments passed. Returns the full path of the file that was edited.

	.PARAMETER Path
	The full path of the configuration file.

	.PARAMETER Url
	The jdbc url to use to connect to the database.

	.PARAMETER User
	The user to use to connect to the database

	.PARAMETER Password
	The password to use to connect to the database.

	.PARAMETER Locations
	A list of locations to scan recursively for migrations.

	.INPUTS
	System.String
	System.IO.FileInfo
	System.IO.DirectoryInfo
	System.Management.Automation.PSCustomObject

	.OUTPUTS
	System.String

	.EXAMPLE
	Edit-FlywayConf "c:\tools\flyway\flyway.conf" -url "localhost" -usr "john" -pwd "pa551";
	In this example, the 'flyway.conf' file is modified using the specified values.

	.LINK
	https://flywaydb.org/documentation
	#>
	[CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
	Param(
		[Alias('c', 'conf', 'path')]
		[Parameter(ValueFromPipeline)]
		$InputObject = "$(Split-Path $PSScriptRoot -Parent)\bin",

		[string]$Url,

		[Alias('u', 'usr')]
		[string]$User,

		[Alias('p', 'pwd')]
		[SecureString]$Password,

		[Alias('l', 'loc')]
		[string[]]$Locations = @()
	)

	# Extract a path from the InputObject if possible.
	$configFile = "";
	if ($InputObject.ConfigFile -ne $null) { $configFile = $InputObject.ConfigFile; }
	elseif (Test-Path $InputObject -PathType Leaf) { $configFile = $InputObject.ToString(); }
	else 
	{ 
		try
		{
			$configFile = Get-ChildItem $InputObject -Recurse -Filter "flyway.conf" | Select-Object -ExpandProperty FullName -First 1;
		}
		catch
		{
			throw "the input object does not represent a 'flyway.conf' file.";
		}
	}

	if ([String]::IsNullOrEmpty($configFile) -or (-not (Test-Path $configFile -PathType Leaf))) { throw "cannot find '$configFile'."; }
	else
	{
		# Tranform the given values into compatible flyway args.
		for ($i = 0; $i -lt $Locations.Length; $i++)
		{
			if (-not $Locations[$i].StartsWith("filesystem")) { $Locations[$i] = "filesystem:$($Locations[$i])"; }
		}

		$loc = [String]::Join(",", $Locations);
		$pwd = (New-Object pscredential "usr", $Password).GetNetworkCredential().Password;

		# Edit the 'flyway.conf' file.
		$content = (Get-Content $configFile | Out-String).Trim();
		$map = @{"url"=$Url;"user"=$User;"password"=$pwd;"locations"="$loc"};
		foreach ($key in $map.Keys)
		{
			$value = $map[$key];
			if (-not [string]::IsNullOrEmpty($value))
			{
				$content = $content -replace "(#\s*)?flyway\.$key=.*", "flyway.$key=$value";
				Write-Verbose "flyway.$key was set to '$value'.";
			}
		}

		if ($PSCmdlet.ShouldProcess($configFile))
		{
			$content | Out-File $configFile -Encoding utf8;
			Write-Verbose "modified '$configFile'.";
		}
	}

	return $configFile;
}
	
