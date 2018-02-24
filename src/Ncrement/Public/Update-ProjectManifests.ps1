<#
.SYNOPSIS
This cmdlet updates all project files within a given directory.

.DESCRIPTION
This cmdlet will update all project files within a given directory using the provided [Manifest] instance. When the -CommitChanged flag is present, all files modified by the cmdlet will be committed to git. Aslo when both the -TagCommit flag and -CommitChanges flag is present the cmdlet will tag the commit with the current version number. Use the -Major and -Minor flags to increment the manifest version number.

The cmdlet returns a [PSCustomObject] containing a list of the files it modified, the [Manifest] object and a boolean that determines whether the git operations were sucessful.

.PARAMETER RootDirectory
The root directory of your project(s).

.PARAMETER Manifest
A [Manifest] object.

.PARAMETER CommitMessage
The message to use when the -CommitChanges flag is present.

.PARAMETER CommitChanges
Determines whether to commit the modified file to source control (using Git).

.PARAMETER TagCommit
Determines whether the Git commit should be tagged with the current version number.

.PARAMETER Major
Determines whether the Major version number should be incremented.

.PARAMETER Minor
Determines whether the Minor version number should be incremented.

.PARAMETER Patch
Determines whether the Patch version number should be incremented.

.OUTPUTS
System.Management.Automation.PSCustomObject

.EXAMPLE
"C:\manifest.json" | Get-BuildboxManifest | Update-ProjectManifests "C:\projects\new_idea" -Minor;
This example increments the project's version number.

.EXAMPLE
"C:\manifest.json" | Get-BuildboxManifest | Update-ProjectManifests "C:\projects\new_idea" -Major -Commit -Tag;
This example increments the project's version number and commits the changes to source control.

.LINK
Get-BuildboxManifest

.LINK
New-BuildboxManifest
#>
function Update-ProjectManifests()
{
	[CmdletBinding()]
	Param(
		[Alias('r', "dir", "root")]
		[Parameter(Mandatory, Position = 1)]
		[string]$Path,

		[Parameter(Mandatory, ValueFromPipeline, Position = 3)]
		[Manifest]$Manifest,

		[Alias('m', "msg")]
		[Parameter(Position = 2)]
		[string]$CommitMessage,

		[Alias('c', "commit")]
		[switch]$CommitChanges,

		[Alias('t', "tag")]
		[switch]$TagCommit,

		[Alias("break")]
		[switch]$Major,

		[Alias("feature")]
		[switch]$Minor,

		[Alias("bug")]
		[switch]$Patch
	)
	
	$modifiedFiles = New-Object System.Collections.ArrayList;

	# Incrementing the manifest version number.
    $oldVersion = $Manifest.Version.ToString();
	$Manifest.Version.Increment($Major.IsPresent, $Minor.IsPresent, $Patch.IsPresent);
	$Manifest.Save();
	$modifiedFiles.Add($Manifest.Path);

	# Update all .NET project files.
	foreach ($projectFile in (Get-ChildItem $Path -Recurse -Filter "*.csproj"))
	{
		$wasUpdated = Update-NetStandardProject $projectFile.FullName $Manifest;
		if ($wasUpdated) { $modifiedFiles.Add($projectFile.FullName); }

		$assemblyInfo = Update-NetFrameworkProject $projectFile.FullName $Manifest;
		if (Test-Path $assemblyInfo -PathType Leaf) { $modifiedFiles.Add($assemblyInfo); }
	}

	# Update all powershell module manifest.
	foreach ($projectFile in (Get-ChildItem $Path -Recurse -Filter "*.psd1"))
	{
		try
		{
			$tags = [string]::Join(' ', $Manifest.Tags.Split(@(' ', ',', ';')));
			Update-ModuleManifest -Path $projectFile.FullName `
			-Author $Manifest.Authors `
			-CompanyName $Manifest.Owner `
			-Description $Manifest.Description `
			-Copyright $Manifest.Copyright `
			-ProjectUri $Manifest.ProjectUrl `
			-ReleaseNotes $Manifest.ReleaseNotes `
			-LicenseUri $Manifest.LicenseUri `
			-IconUri $Manifest.IconUri `
			-Tags $tags `
			-ModuleVersion $Manifest.Version.ToString();

			$modifiedFiles.Add($projectFile.FullName);
		}
		catch { Write-Warning $_.Exception.Message; }
	}

	# Update all '.vsixmanifest' files
	foreach ($projectFile in (Get-ChildItem $Path -Recurse -Filter "*.vsixmanifest"))
	{
		Update-VSIXManifest $projectFile.FullName $Manifest;
		$modifiedFiles.Add($projectFile.FullName);
	}

	# Commit Changes
	if ($CommitChanges -and (Assert-GitIsInstalled))
	{
		foreach ($file in $modifiedFiles) { &git add $file; }

		$msg = "";
		$version = $Manifest.Version.ToString();
		if ([string]::IsNullOrEmpty($CommitMessage))
		{
			$msg = "Increment version number to $version";
		}
		else
		{
			$msg = [string]::Format($CommitMessage, $version);
		}
		&git commit -m $msg;
		if ($TagCommit) { &git tag v$version; }
	}

	return New-Object PSCustomObject -Property @{
		"Manifest"=$Manifest;
		"ModifiedFiles"=$modifiedFiles;
        "OldVersion"=$oldVersion;
        "Version"=$Manifest.Version.ToString();
	};
}

function Update-NetStandardProject([string]$projectFile, $manifest)
{
	[xml]$doc = Get-Content $projectFile;
	$netstandardProject = &{ try { return ($doc.SelectSingleNode("//Project[@Sdk]") -ne $null); } catch { return $false; } };

	if ($netstandardProject)
	{
		$propertyGroup = $doc.SelectSingleNode("/Project/PropertyGroup[1]");
		foreach ($arg in @(
			[Arg]::new("Title", $manifest.ProductName),
			[Arg]::new("AssemblyVersion", $manifest.Version.ToString()),
			[Arg]::new("PackageVersion", $manifest.Version.ToString()),
			[Arg]::new("Description", $manifest.Description),
			[Arg]::new("Authors", $manifest.Authors),
			[Arg]::new("Company", $manifest.Owner),
			[Arg]::new("PackageTags", $manifest.Tags),
			[Arg]::new("Copyright", $manifest.Copyright),
			[Arg]::new("PackageIconUrl", $manifest.IconUri),
			[Arg]::new("PackageProjectUrl", $manifest.ProjectUrl),
			[Arg]::new("PackageLicenseUrl", $manifest.LicenseUri),
			[Arg]::new("PackageReleaseNotes", $manifest.ReleaseNotes),
			[Arg]::new("RepositoryUrl", $manifest.RepositoryUrl)
		))
		{
			if (-not [string]::IsNullOrEmpty($arg.Value))
			{
				$element = $doc.SelectSingleNode("//PropertyGroup/$($arg.TagName)");
				if ($element -eq $null)
				{
					$node = $doc.CreateElement($arg.TagName);
					$data = &{ if ($arg.Value -match '(\n|[><])') { return $doc.CreateCDataSection($arg.Value); } else { return $doc.CreateTextNode($arg.Value); }};
					$node.AppendChild($data);
					$propertyGroup.AppendChild($node);
				}
				else
				{
					$element.InnerText = $arg.Value;
				}
			}
		}
		$doc.Save($projectFile);
	}
	return $netstandardProject;
}

function Update-NetFrameworkProject([string]$projectFile, $manifest)
{
	$assemblyInfo = "$(Split-Path $projectFile -Parent)\Properties\AssemblyInfo.cs";
	if (Test-Path $assemblyInfo)
	{
		$contents = Get-Content $assemblyInfo | Out-String;
		foreach ($arg in @(
			[Arg]::new("Company", "`"$($manifest.Owner)`""),
			[Arg]::new("Description", "`"$($manifest.Description)`""),
			[Arg]::new("Copyright", "`"$($manifest.Copyright)`""),
			[Arg]::new("InformationalVersion", "`"$($manifest.Version.ToString())`""),
			[Arg]::new("FileVersion", "`"$($manifest.Version.ToString())`""),
			[Arg]::new("Version", "`"$($manifest.Version.ToString())`"")
		))
		{
			if (-not [string]::IsNullOrEmpty($arg.Value))
			{
				$matches = [Regex]::Matches($contents, [string]::Format('(?i)Assembly{0}\s*\(\s*(?<value>"?.*"?)\)', $arg.TagName));
				if ($matches.Count -ge 1)
				{
					foreach ($match in $matches)
					{
						$value = $match.Groups["value"];
						$contents = $contents.Remove($value.Index, $value.Length);
						$contents = $contents.Insert($value.Index, $arg.Value);
					}
				}
				else
				{
					$contents = [string]::Concat($contents.TrimEnd(), [System.Environment]::NewLine, "[assembly: Assembly$($arg.TagName)($($arg.Value))]");
				}
			}
		}
		$contents | Out-File $assemblyInfo -Encoding utf8;
	}
	return $assemblyInfo;
}

function Update-VSIXManifest([string]$projectFile, $manifest)
{
	[xml]$doc = Get-Content $projectFile;
    $ns = New-Object Xml.XmlNamespaceManager $doc.NameTable;
    $ns.AddNamespace("x", "http://schemas.microsoft.com/developer/vsx-schema/2011");

	$metadata = $doc.SelectSingleNode("//x:Metadata", $ns);
	if ($metadata -ne $null)
	{
		$identity = $metadata.SelectSingleNode("x:Identity", $ns);
		foreach ($arg in @(
			[Arg]::new("Version", $manifest.Version.ToString()),
			[Arg]::new("Publisher", $manifest.Owner)
		))
		{
			if (-not [string]::IsNullOrEmpty($arg.Value))
			{
				$attribute = $identity.Attributes[$arg.TagName];
				if ($attribute -eq $null)
				{
					$attr = $doc.CreateAttribute($arg.TagName);
					$attr.Value = $arg.Value;
                    $identity.Attributes.Append($attr);
				}
				else
				{
					$attribute.Value = $arg.Value;
				}
			}
		}
		foreach ($arg in @(
			[Arg]::new("DisplayName", $manifest.ProductName),
			[Arg]::new("Description", $manifest.Description),
			[Arg]::new("Tags", $manifest.Tags)
		))
		{
			if (-not [string]::IsNullOrEmpty($arg.Value))
			{
				$node = $metadata.SelectSingleNode("x:$($arg.TagName)", $ns);
				if ($node -eq $null)
				{
					$n = $doc.CreateElement($arg.TagName, "http://schemas.microsoft.com/developer/vsx-schema/2011");
					$data = &{ if ($arg.Value -match '[\n><]') { return $doc.CreateCDataSection($arg.Value); } else { return $doc.CreateTextNode($arg.Value); } };
					$n.AppendChild($data);
					$metadata.AppendChild($n);
				}
				else
				{
					$node.InnerText = $arg.Value;
				}
			}
		}
		$doc.Save($projectFile) | Out-Null;
	}
}

class Arg
{
	Arg([string]$tagName, [string]$value)
	{
		$this.Value = $value;
		$this.TagName = $tagName;
	}

	[string]$Value;
	[string]$TagName;
}