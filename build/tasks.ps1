<#
.SYNOPSIS
Psake build tasks.
#>

Properties {
    # Paths
    $RootDir = (Split-Path $PSScriptRoot -Parent);
    $ArtifactsDir = "$RootDir\artifacts";

    # Tools
    $nuget = "";

    # Enviroment Args
    $Branch = "";
    $ReleaseTag = "";
    $BuildConfiguration = "";

    # User Args
    $TestName = $null;
    $Config = $null;
    $NuGetKey = "";
    $PsGalleryKey = "";
}

Task "setup" -description "Run this task to help configure your local enviroment for development." -depends @("Init");

# -----

Task "Init" -description "This task load all dependencies." -action {
    foreach ($folder in @("$ArtifactsDir\nuget"))
    {
		if (Test-Path $folder -PathType Container)
		{ Remove-Item $folder -Recurse -Force; }

		New-Item $folder -ItemType Directory | Out-Null;
    }
    
    foreach ($psm1 in (Get-ChildItem "$RootDir\build" -Filter "*.psm1" | Select-Object -ExpandProperty FullName))
    {
        Import-Module $psm1 -Force;
        Write-Host "`t* $(Split-Path $psm1 -Leaf) imported.";
    }

    $pester = Get-Item "$RootDir\packages\Pester.*\tools\Pester.psm1" | Select-Object -ExpandProperty FullName;
    Import-Module $pester;
    Write-Host "`t* pester imported.";
}


Task "Cleanup" -description "This task releases all resources." -action {
    
}


Task "Build-Solution" -alias "compile" -description "This task compile the solution." `
-depends @("Init") -action {
    Assert ("Debug", "Release" -contains $BuildConfiguration) "`$BuildConfiguration was '$BuildConfiguration' but expected 'Debug' or 'Release'.";

    $sln = Get-Item "$RootDir\*.sln" | Select-Object -ExpandProperty FullName;
    Write-Breakline "MSBUILD";
    Exec { msbuild $sln "/p:Configuration=$BuildConfiguration;Platform=Any CPU"; };
    Write-BreakLine;
}


Task "Run-Pester" -alias "pester" -description "This task invoke all selected pester tests." `
-depends @("Init") -action {
    if ([String]::IsNullOrEmpty($TestName))
    { 
        foreach($script in (Get-ChildItem "$RootDir\tests" -Recurse -Filter "*.tests.ps1" | Select-Object -ExpandProperty FullName))
        {
            echo "s: $script";
        }
    }
    else
    {
        $script = Get-ChildItem "$RootDir\tests" -Recurse -Filter "*$TestName*.ps1" | Select-Object -ExpandProperty FullName -First 1;
        Invoke-Pester -Script $script;
    }
}


Task "Run-Tests" -alias "test" -description "This task runs all tests." `
-depends @("Build-Solution") -action {
    # Pester Tests
    Write-BreakLine "PESTER";
    foreach ($test in (Get-ChildItem "$RootDir\tests" -Recurse -Filter "*.tests.ps1" | Select-Object -ExpandProperty FullName))
    { Invoke-Pester -Script $test; }
    Write-BreakLine;

    Write-BreakLine "VSTEST";
    foreach ($proj in (Get-ChildItem "$RootDir\tests" -Recurse -Filter "*.*proj" | Select-Object -ExpandProperty FullName))
    {
        try
        {
            Push-Location (Split-Path $proj -Parent);
            Exec { & dotnet test; }
        }
        finally { Pop-Location; }
    }
    Write-BreakLine;
}


Task "Increment-Version" -alias "version" -description "This task increment the the version number of each project." `
-depends @() -action {
    $version = $config.version;
    $version.patch = ([Int]::Parse($version.patch) + 1);
    $value = "$($version.major).$($version.minor).$($version.patch)";
    $config | ConvertTo-Json | Out-File "$PSScriptRoot\config.json";

    foreach ($proj in (Get-ChildItem "$RootDir\src" -Recurse -Filter "*.*proj" | Select-Object -ExpandProperty FullName))
    {
        $extension = [IO.Path]::GetExtension($proj);

        if ($extension -eq ".csproj")
        {
            $assemblyInfo = "$(Split-Path $proj -Parent)\Properties\AssemblyInfo.cs";
            $content = Get-Content $assemblyInfo | Out-String;
            $content = $content = $content -replace '"(\d+\.?)+"', "`"$value`"";
            $content | Out-File $assemblyInfo;

            Exec { 
                & git add $assemblyInfo;
                & git commit -m "Update $(Split-Path $proj -Leaf) version to $value";
            }
        }
        
        if ($extension -eq ".pssproj")
        {
            $manifest = [IO.Path]::ChangeExtension($proj, "psd1");
            if (Test-Path $manifest -PathType Leaf)
            {
                $content = Get-Content $manifest | Out-String;
                $content = $content -replace 'ModuleVersion(\s)*=(\s)*(''|")(?<ver>\d\.?)+(''|")', "ModuleVersion = '$value'";
                $content | Out-File $manifest -Encoding utf8;

                Exec { 
                    & git add $manifest;
                    & git commit -m "Update $(Split-Path $proj -Leaf) version to $value";
                }
            }
        }
    }

    Write-Host "`t* new version $value";
}


Task "Create-Packages" -alias "pack" -description "This task generates a nuget package for each project." `
-depends @("Init", "Increment-Version", "Run-Tests") -action {
    foreach ($proj in (Get-ChildItem "$RootDir\src" -Recurse -Filter "*.*proj" | Select-Object -ExpandProperty FullName))
    {
        $extension = [IO.Path]::GetExtension($proj);
        
        if ($extension -eq ".csproj")
        {
            $nuspec = [IO.Path]::ChangeExtension($proj, ".nuspec");
            $outDir = "$ArtifactsDir\nuget";

            if (-not (Test-Path $outDir -PathType Container)) { New-Item $outDir -ItemType Directory | Out-Null; }
            
            if (Test-Path $nuspec -PathType Leaf)
            {
                [xml]$nuspecDef = Get-Content $nuspec;
                
                $nuspecDef.SelectSingleNode("package/metadata/projectUrl").InnerText = $Config.project.site;
                $nuspecDef.SelectSingleNode("package/metadata/licenseUrl").InnerText = $Config.project.license;
                $nuspecDef.SelectSingleNode("package/metadata/iconUrl").InnerText = $Config.project.icon;
                if (-not [String]::IsNullOrEmpty($ReleaseTag))
                {
                    $nuspecDef.SelectSingleNode("package/metadata/version").InnerText = "$($Config.version.major).$($Config.version.minor).$($Config.version.patch)-$ReleaseTag";
                }
                $nuspecDef.Save($nuspec);
                
                Write-BreakLine "NUGET";
                Exec { & $nuget pack $proj -OutputDirectory $outDir -Prop "Configuration=$BuildConfiguration" -IncludeReferencedProjects; }
                Write-BreakLine;
            }
        }
    }
}


Task "Publish-Packages" -alias "publish" -description "Publish all nuget packages to 'nuget.org' and 'powershell gallery'." `
-depends @("Create-Packages") -action {
    Assert (-not [String]::IsNullOrEmpty($NuGetKey)) "The 'nuget api key' was not assinged.";
    Assert (-not [String]::IsNullOrEmpty($PsGalleryKey)) "The 'PS Gallery api key' was not assigned.";

    foreach ($manifest in (Get-ChildItem "$RootDir\src" -Recurse -Filter "*.psd1" | Select-Object -ExpandProperty FullName))
    {
        $releaseNotes = "";
        $path = "$(Split-Path $manifest -Parent)\releaseNotes.txt";
        if (Test-Path $path -PathType Leaf)
        { $releaseNotes = Get-Content $path | Out-String; }
        
        Write-Host "`t* verifying $(Split-Path $manifest -Leaf) manifest ...";
        if (Test-ModuleManifest $manifest)
        {
            Update-ModuleManifest $manifest -ReleaseNotes $releaseNotes;
            Update-ModuleManifest $manifest -LicenseUri $config.project.license;
            Update-ModuleManifest $manifest -IconUri $config.project.icon;
            Update-ModuleManifest $manifest -ProjectUri $config.project.site;
            
            Publish-Module -Name $manifest -NuGetApiKey $PsGalleryKey;
            Write-Host "`t* published $(Split-Path $manifest -Leaf) to 'https://www.powershellgallery.com'." -ForegroundColor Green;
        }
    }

    foreach ($package in (Get-ChildItem $ArtifactsDir -Recurse -Filter "*.nupkg" | Select-Object -ExpandProperty FullName))
    {
        Write-BreakLine "NUGET";
        Exec { & $nuget push $package -Source $config.nuget.source -ApiKey $NuGetKey; }
        Write-BreakLine;
    }
}
