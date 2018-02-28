# Ncrement
[![NuGet](https://img.shields.io/nuget/v/Acklann.Ncrement.svg)](https://www.nuget.org/packages/Acklann.Ncrement/)
[![NuGet](https://img.shields.io/nuget/dt/Acklann.Ncrement.svg)](https://www.nuget.org/packages/Acklann.Ncrement/)
---

## What it is?

Ncrement is a **easy to use** powershell module for applying **semantic versioning** to your projects. Ncrement can synchronize all projects within your solution with the same version and metadata; no more complicated scripts to perform such a time-consuming task.

## How it works?

Ncrement uses a `manifest.json` file to store the current version and metadata about your solution. The file can be anywhere and should be committed to source control [(here is an example)](/samples/manifest.json). The information stored within the `manifest.json` file will be used update the project file in your solution. To update your projects, Ncrement has 3 main functions that can be piped together `Get-NcrementManifest | Step-NcrmentVersionNumber | Update-NcrementProjectFile`.

**[Get-NcrementManifest](/src/Ncrement/Public/Get-NcrementManifest.ps1)**

This function will deserialize the `manifest.json` file into an object. It also accepts a path to the `manifest.json` file, therefore the file do not have to be named "manifest.json".

**[Step-NcrementVersionNumber](/src/Ncrement/Public/Step-NcrementVersionNumber.ps1)**

This function will take the deserialized `manifest.json` file and increment it's version number. It accepts the following switches to increment the respective numbers `-Major`, `-Minor` and `-Patch`. 

**[Update-NcrementProjectFile](/src/Ncrement/Public/Update-NcrementProjectFile.ps1)**

This function will take the deserialized `manifest.json` file and use it to update all supported project files. It accepts a full-path to the directory you wish to update. In addition, by using the `-Commit` and `-Tag` switches it will commit all files it modified to source control (*GIT*) then tag that commit with the version number.

**Example:** 
```powershell
$result = "C:\projects\myapp" | Get-NcremnetManifest | Step-NcrementVersionNumber -Patch | Update-NcrementProjectFile "C:\projects\myapp\src" -Tag -Commit`;
```


