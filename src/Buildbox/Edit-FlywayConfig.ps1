function Edit-FlywayConfig()
{
	<#
	.SYNOPSIS
	This cmdlet helps with the editing of a 'flyway.conf' file.

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

	.EXAMPLE
	Edit-FlywayConfig "c:\tools\flyway\flyway.conf" -url "localhost" -usr "john" -pwd "pa551";
	In this example, the 'flyway.conf' file is modified using the specified values.

	.LINK
	https://flywaydb.org/documentation
	#>
	[CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
	Param(
		[string]$Path,

		[string]$Url,

		[Alias('u', 'usr')]
		[string]$User,

		[Alias('p', 'pwd')]
		[SecureString]$Password,

		[Alias('l', 'loc')]
		[string[]]$Locations
	)

	if ([String]::IsNullOrEmpty($Path))
	{
		$Path = Get-ChildItem $PSScriptRoot -Recurse -Filter "flyway.conf" | Select-Object -ExpandProperty FullName -First 1;
	}

	if ([String]::IsNullOrEmpty($Path) -or (-not (Test-Path $Path -PathType Leaf))) { throw "cannot find '$Path'."; }
	else
	{
		Write-Verbose "modifying '$Path' ...";
		for ($i = 0; $i -lt $Locations.Length; $i++)
		{
			if (-not $Locations[$i].StartsWith("filesystem")) { $Locations[$i] = "filesystem:$($Locations[$i])"; }
		}

		$loc = [String]::Join(",", $Locations);
		$pwd = (New-Object pscredential "usr", $Password).GetNetworkCredential().Password;

		$content = (Get-Content $Path | Out-String).Trim();
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

		if ($PSCmdlet.ShouldProcess($Path))
		{
			$content | Out-File $Path -Encoding utf8;
			Write-Verbose "modified '$Path'.";
		}
	}
}