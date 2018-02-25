
NAME
    Get-NcrementManifest
    
SYNOPSIS
    Creates a new [Manifest] instance from the specified path.
    
    
SYNTAX
    Get-NcrementManifest [[-Path] <String>] [-CreateIfNotFound] [<CommonParameters>]
    
    
DESCRIPTION
    This function creates a new [Manifest] instance from the given path. If no path is given 
    the funtion will search the current directory for a 'manifest.json' file; Passing a path 
    to a directory will also invoke the same behavior.
    

PARAMETERS
    -Path <String>
        The path of the manifest file.
        
        Required?                    false
        Position?                    1
        Default value                
        Accept pipeline input?       true (ByValue)
        Accept wildcard characters?  false
        
    -CreateIfNotFound [<SwitchParameter>]
        Determines wether to create a new 'manifest.json' file if none exist at the specified 
        path.
        
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see 
        about_CommonParameters (https:/go.microsoft.com/fwlink/?LinkID=113216). 
    
INPUTS
    [String]
    
    
OUTPUTS
    [Manifest]
    
    
    -------------------------- EXAMPLE 1 --------------------------
    
    PS C:\>Get-NcrementManifest;
    
    This example creates a new [Manifest] from the 'manifest.json' file withing the current 
    directory.
    
    Get-NcrementManifest "C:\newproject\manifest.json";
    This example creates a new [Manifest] from the specified path.
    
    
    
    
    
RELATED LINKS
    New-NcrementManifest 





