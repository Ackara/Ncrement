# Ncrement
[![PSGallery](https://img.shields.io/powershellgallery/v/Ncrement.svg)](https://www.powershellgallery.com/packages/Ncrement)

## The Problem

Your application is composed of one or more projects and you need to keep their version number in-sync. 

## The solution

**Ncrement** is a powershell module that help you to apply **semantic versioning** to your projects. It can also synchronize your projects metadata;  by utilizing a `.json` file to store the current version and metadata of your solution, Ncrement can inject said information into a project file.

### Usage

Ncrement is available on [powershell gallery](https://www.powershellgallery.com/packages/Ncrement/) `PS> Save-Module -Name Ncrement -Path <path>`

**[New-NcrementManifest](src/Ncrement/Public/New-NcrementManifest.ps1)**

Creates a new `[PSObject]` that you can use to store your application's version number and metadata. The returned object will contain properties for the version number.

```powershell
# Example: 
New-NcrementManifest | ConvertTo-Json | Out-File "manifest.json";
# creates a new '.json' file.
# sample: { name: "", website: "", version: { major: 1, minor: 0, patch: 3} ... }
```

**[Step-NcrementVersionNumber](src/Ncrement/Public/Step-NcrementVersionNumber.ps1)**

Takes a *[Manifest]* Object as a file or `[PSObject]` and increments its version number.

```powershell
# Example: 
"C:\app\maifest.json" | Step-NcrementVersionNumber -Minor | ConvertTo-Json | Out-File "C:\app\manifest.json";
# before: {version: { major: 1, minor: 0, patch: 3}}
# after:  {version: { major: 1, minor: 1, patch: 0}}
```

**[Update-NcrementProjectFile](src/Ncrement/Public/Update-NcrementProjectFile.ps1)**

Takes a project file and a *[Manifest]* object then updates the project's file using the information in the *[Manifest]* object.

```powershell
# Example:
$manifest = Get-Content "C:\app.csproj" | ConvertFrom-Json;
Get-ChildItem -Filter "*.csproj" | Update-NcrementProjectFile $manifest -Commit;
# When the commit [switch] is present the modified files will be committed to source control.
```

Ncrement can update the following project files:

| File-Type      | Description |
|----------------|-------------|
| *.*proj        | Any .NET project file.
| *.vsixmanifest | Visual Studio Extension manifest file.
| *.psd1         | Powershell module manifest.
| package.json   | Node project file.
