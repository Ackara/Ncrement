function Write-LineBreak ([string]$Title = "") {
	$line = "`n----------------------------------------------------------------------";
	$limit = $line.Length;
	if (-not [String]::IsNullOrEmpty($Title))
	{
		$line = $line.Insert(4, " $Title ");
		if ($line.Length -gt $limit) { $line = $line.Substring(0, $limit); }
	}

	Write-Host $line; Write-Host "";
}


function Install-FlywayCLI()
{
	<#
	.SYNOPSIS
	Installs the flyway command-line tool from 'https://flywaydb.org' to the specified directory.

	.PARAMETER InstallationPath
	The installation path.

	.PARAMETER Version
	The version number. (default: 4.2.0).

	.INPUTS
	[String]

	.OUTPUTS
	[String]

	.EXAMPLE
	Install-FlywayCLI "c:\temp";
	In this example, the flyway cli is downloaded into a temp directory.

	.EXAMPLE
	Install-FlywayCLI "c:\temp";
	In this example, the flyway cli is downloaded into the current directory.

	.LINK
	https://flywaydb.org/documentation/
	#>

	Param(
		[Alias('path', 'p')]
		[string]$InstallationPath = $PWD,

		[Alias('v', 'ver')]
		[string]$Version = "4.2.0"
	)

	$flyway = Get-ChildItem $InstallationPath -Recurse -Filter "flyway.cmd" | Select-Object -ExpandProperty FullName -First 1;
	if ([String]::IsNullOrEmpty($flyway) -or (-not (Test-Path $flyway -PathType Leaf)))
	{
		$archive = "$InstallationPath\flyway.zip";
		try
		{
			if (-not (Test-Path $InstallationPath -PathType Container)) { New-Item $InstallationPath -ItemType Directory | Out-Null; }
			if (-not (Test-Path $archive -PathType Leaf)) { Invoke-WebRequest "https://repo1.maven.org/maven2/org/flywaydb/flyway-commandline/$Version/flyway-commandline-$Version-windows-x64.zip" -OutFile $archive; }
			Expand-Archive $archive -DestinationPath $InstallationPath;
			$flyway = Get-ChildItem $InstallationPath -Recurse -Filter "flyway.cmd" | Select-Object -ExpandProperty FullName -First 1;
		}
		finally
		{
			if (Test-Path $archive -PathType Leaf) { Remove-Item $archive -Force; }
		}
	}

	return $flyway;
}

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

		[Alias('usr')]
		[string]$User,

		[Alias('pwd')]
		[SecureString]$Password,

		[Alias('loc')]
		[string[]]$Locations
	)

	if ([String]::IsNullOrEmpty($Path))
	{
		$Path = Get-ChildItem $Path -Recurse -Filter "flyway.conf" | Select-Object -ExpandProperty FullName -First 1;
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

function Install-WawsDeploy()
{
	<#
	.SYNOPSIS
	Installs the wawsdeploy command-line tool from 'https://chocolatey.org/' to the specified directory.

	.PARAMETER InstallationPath
	The installation path.

	.PARAMETER Version
	The version number. (default: 1.8.0).

	.EXAMPLE
	Install-WawsDeploy "C:\temp";
	In this example, the wawsdeploy cli is downloaded into a temp directory.

	.EXAMPLE
	Install-WawsDeploy;
	In this example, the wawsdeploy cli is downloaded into the current directory.

	.LINK
	https://chocolatey.org/packages/WAWSDeploy
	.LINK
	https://github.com/davidebbo/WAWSDeploy
	#>

	Param(
		[Alias("path")]
		[string]$InstallationPath,

		[Alias("pwd")]
		[string]$Version = "1.8.0"
	)

	$waws = Get-ChildItem $InstallationPath -Recurse -Filter "*WAWSDeploy.exe" | Select-Object -ExpandProperty FullName -First 1;
	if ([String]::IsNullOrEmpty($waws) -or (-not (Test-Path $waws -PathType Leaf)))
	{
		$nupkg = "$InstallationPath\waws.zip";
		try
		{
			if (-not (Test-Path $InstallationPath -PathType Container)) { New-Item $InstallationPath -ItemType Directory | Out-Null; }
			if (-not (Test-Path $nupkg -PathType Leaf)) { Invoke-WebRequest "https://chocolatey.org/api/v2/package/WAWSDeploy/$Version" -OutFile $nupkg; }

			$wawsDir = "$InstallationPath\wawsdeploy-$Version";
			Expand-Archive $nupkg -DestinationPath $wawsDir;
			Get-ChildItem "$wawsDir\tools" | Move-Item -Destination $wawsDir;
			Get-ChildItem $wawsDir -Recurse -Exclude @("WAWSDeploy.exe*", "Args.dll") | Remove-Item -Recurse -Force;
			$waws = Get-ChildItem $InstallationPath -Recurse -Filter "WAWSDeploy.exe" | Select-Object -ExpandProperty FullName -First 1;
		}
		finally
		{
			if (Test-Path $nupkg -PathType Leaf) { Remove-Item $nupkg; }
		}
	}

	return $waws;
}

function Show-Inputbox([string]$Message, [string]$WindowTitle = "Please enter some text.", [string]$DefaultText)
{
	<#
	.SYNOPSIS
	Prompts the user with a multi-line input box and returns the text they enter, or null if they cancelled the prompt.

	.DESCRIPTION
	Prompts the user with a multi-line input box and returns the text they enter, or null if they cancelled the prompt.

	.PARAMETER Message
	The message to display to the user explaining what text we are asking them to enter.

	.PARAMETER WindowTitle
	The text to display on the prompt window's title.

	.PARAMETER DefaultText
	The default text to show in the input box.

	.EXAMPLE
	$userText = Show-Inputbox "Input some text please:" "Get User's Input"

	Shows how to create a simple prompt to get mutli-line input from a user.

	.EXAMPLE
	# Setup the default multi-line address to fill the input box with.
	$defaultAddress = @'
	John Doe
	123 St.
	Some Town, SK, Canada
	A1B 2C3
	'@

	$address = Show-Inputbox "Please enter your full address, including name, street, city, and postal code:" "Get User's Address" $defaultAddress
	if ($address -eq $null)
	{
		Write-Error "You pressed the Cancel button on the multi-line input box."
	}

	Prompts the user for their address and stores it in a variable, pre-filling the input box with a default multi-line address.
	If the user pressed the Cancel button an error is written to the console.

	.EXAMPLE
	$inputText = Show-Inputbox -Message "If you have a really long message you can break it apart`nover two lines with the powershell newline character:" -WindowTitle "Window Title" -DefaultText "Default text for the input box."

	Shows how to break the second parameter (Message) up onto two lines using the powershell newline character (`n).
	If you break the message up into more than two lines the extra lines will be hidden behind or show ontop of the TextBox.

	.NOTES
	Name: Show-MultiLineInputDialog
	Author: Daniel Schroeder (originally based on the code shown at http://technet.microsoft.com/en-us/library/ff730941.aspx)
	Version: 1.0
	#>

	Add-Type -AssemblyName System.Drawing
	Add-Type -AssemblyName System.Windows.Forms

	# Create the Label.
	$label = New-Object System.Windows.Forms.Label
	$label.Location = New-Object System.Drawing.Size(10,10)
	$label.Size = New-Object System.Drawing.Size(280,20)
	$label.AutoSize = $true
	$label.Text = $Message

	# Create the TextBox used to capture the user's text.
	$textBox = New-Object System.Windows.Forms.TextBox
	$textBox.Location = New-Object System.Drawing.Size(10,40)
	$textBox.Size = New-Object System.Drawing.Size(575,200)
	$textBox.AcceptsReturn = $true
	$textBox.AcceptsTab = $false
	$textBox.Multiline = $true
	$textBox.ScrollBars = 'Both'
	$textBox.Text = $DefaultText

	# Create the OK button.
	$okButton = New-Object System.Windows.Forms.Button
	$okButton.Location = New-Object System.Drawing.Size(415,250)
	$okButton.Size = New-Object System.Drawing.Size(75,25)
	$okButton.Text = "OK"
	$okButton.Add_Click({ $form.Tag = $textBox.Text; $form.Close() })

	# Create the Cancel button.
	$cancelButton = New-Object System.Windows.Forms.Button
	$cancelButton.Location = New-Object System.Drawing.Size(510,250)
	$cancelButton.Size = New-Object System.Drawing.Size(75,25)
	$cancelButton.Text = "Cancel"
	$cancelButton.Add_Click({ $form.Tag = $null; $form.Close() })

	# Create the form.
	$form = New-Object System.Windows.Forms.Form
	$form.Text = $WindowTitle
	$form.Size = New-Object System.Drawing.Size(610,320)
	$form.FormBorderStyle = 'FixedSingle'
	$form.StartPosition = "CenterScreen"
	$form.AutoSizeMode = 'GrowAndShrink'
	$form.Topmost = $True
	$form.AcceptButton = $okButton
	$form.CancelButton = $cancelButton
	$form.ShowInTaskbar = $true

	# Add all of the controls to the form.
	$form.Controls.Add($label)
	$form.Controls.Add($textBox)
	$form.Controls.Add($okButton)
	$form.Controls.Add($cancelButton)

	# Initialize and show the form.
	$form.Add_Shown({$form.Activate()})
	$form.ShowDialog() > $null   # Trash the text of the button that was clicked.

	# Return the text that the user entered.
	return $form.Tag
}