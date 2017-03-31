$Script:WAWSDeploy = "$PSScriptRoot\bin\wawsdeploy\WAWSDeploy.exe";

<#
.SYNOPSIS
Download WAWSDeploy in the current directory.

.PARAMETER Version
The version number.

.INPUTS
None

.OUTPUTS
None
#>
function Install-WAWSDeploy([string]$Version = "1.8.0")
{
	if (-not (Test-Path $Script:WAWSDeploy -PathType Leaf))
	{
		$zip = "$PSScriptRoot\wawsdeploy.zip";

		try
		{
			if (-not (Test-Path $zip -PathType Leaf))
			{
				Write-Verbose "downloading WAWSDeploy from  https://chocolatey.org ...";
				Invoke-WebRequest "https://chocolatey.org/api/v2/package/WAWSDeploy/$Version" -OutFile $zip;
				Write-Verbose "download complete.";
			}

			$wawsDir = Split-Path $Script:WAWSDeploy -Parent;
			if (Test-Path $wawsDir -PathType Container) { Remove-Item $wawsDir -Recurse -Force; }
			New-Item $wawsDir -ItemType Directory | Out-Null;
			Expand-Archive $zip $wawsDir;
			Get-ChildItem $wawsDir -Exclude @("tools") | Remove-Item -Recurse -Force;
			Get-ChildItem "$wawsDir\tools" | Move-Item -Destination $wawsDir;
			Remove-Item "$wawsDir\tools";

			Write-Verbose "WAWSDeploy was installed.";
		}
		finally { if (Test-Path $zip -PathType Leaf) { Remove-Item $zip -Force; } }
	}
}

<#
.SYNOPSIS
Publish a website to a web server using web deploy.

.PARAMETER Site
The path to the site's folder or '.zip' file.

.PARAMETER PublishSettings
The path to the '.publishSettings' file.

.PARAMETER Password
The web deploy password.

.PARAMETER Rule
The deployment rule to enable.

.PARAMETER DeleteExistingFiles
Determines whether to remove all old files before publishing.

.PARAMETER AppOffline
Determines whether the app should be switched off before publishing.

.INPUTS
None

.OUTPUTS
None

.LINK
https://github.com/Ackara/Buildbox
#>
function Invoke-WAWSDeploy()
{
	[CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
	Param (
		[Parameter(Mandatory)]
		[string]$Site,

		[Parameter(Mandatory)]
		[string]$PublishSettings,

		[string]$Password,
		[string]$Rule,

		[switch]$DeleteExistingFiles,
		[switch]$AppOffline
	)

	if ($PSCmdlet.ShouldProcess("site: $Site, settings: $PublishSettings"))
	{
		Install-WAWSDeploy;

		if (Test-Path $Site)
		{
			if (Test-Path $PublishSettings -PathType Leaf)
			{
				$pwd = "";
				if (-not ([String]::IsNullOrEmpty($Password))) { $pwd = "/p $Password"; }

				$deleteFiles = "";
				if ($DeleteExistingFiles) { $deleteFiles = "/d"; }

				$offline = "";
				if ($AppOffline) { $offline = "/appoffline"; }

				if (-not ([String]::IsNullOrEmpty($Rule))) { $Rule = "/rule $Rule"; }

				$options = (("$pwd $deleteFiles $offline").Trim().Split(" ", [StringSplitOptions]::RemoveEmptyEntries));

				(& $Script:WAWSDeploy $Site $PublishSettings $options);
			}
			else { throw "cannot find $PublishSettings."; }
		}
		else { throw "cannot find $Site."; }
	}
}
