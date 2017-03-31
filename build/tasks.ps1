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

    # API Keys
    $NuGetKey = "";
    $PsGalleryKey = "";
}

Task "setup" -description "Run this task to help configure your local enviroment for development." -depends @("Init");

# -----

Task "Init" -description "This task load all dependencies." -action {
    foreach ($folder in @($ArtifactsDir))
    {
		if (Test-Path $folder -PathType Container)
		{ Remove-Item $folder -Force; }

		New-Item $folder -ItemType Directory | Out-Null;
    }
}


Task "Cleanup" -description "This task releases all resources." -action {
}


Task "Run-Tests" -alias "test" -description "This task runs all tests." -action {
}


Task "Create-Nuspec" -alias "spec" -description "This task generates a nuspec file for each module." -action {
}


Task "Create-Packages" -alias "pack" -description "This tasks generates a nuget package for each module." `
-depends @("Run-Tests") -action {
}


Task "Publish-Packages" -alias "publish" -description "This tasks publishes all nuget packages to 'nuget.org' and 'powershell gallery'." `
-depends @("Create-Packages") -action {
    #Assert (-not [String]::IsNullOrEmpty($PsGalleryKey)) "The 'PS Gallery api key' was not assigned.";
    #Assert (-not [String]::IsNullOrEmpty($NuGetKey)) "The 'nuget api key' was not assinged.";
    
    foreach ($package in (Get-ChildItem "$RootDir\src" -Recurse -Filter "*.nupkg" | Select-Object -ExpandProperty FullName))
    {
    }
}
