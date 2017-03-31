<#
.SYNOPSIS
Psake build tasks
#>

Properties {
    # Paths
    $RootDir = (Split-Path $PSScriptRoot -Parent);
    $ArtifactsDir = "$RootDir\artifacts";
}

Task "setup" -description "" -depends @();

# ---

Task "Init" -description "" -action {
    foreach ($folder in @($ArtifactsDir))
    {
    }
}

Task "Cleanup" -description "" -action {
}


Task "Run-Tests" -description "This task ." -action {
}


Task "Create-Packages" -description "" -action {
}


Task "Publish-Packages" -description "" -action {
}
