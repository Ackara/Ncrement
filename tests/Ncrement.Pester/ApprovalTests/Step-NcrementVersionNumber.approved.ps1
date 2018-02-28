
NAME
    Step-NcrementVersionNumber
    
SYNOPSIS
    Increments the specified [Manifest] version number.
    
    
SYNTAX
    Step-NcrementVersionNumber [-Manifest] <Object> [[-Branch] <String>] [-Major] [-Minor] 
    [-Patch] [-DoNotSave] [<CommonParameters>]
    
    
DESCRIPTION
    This function increments the [Manifest] version number. Also when invoked, the version 
    will be incremented then the modified [Manifest] object will be saved to disk as well.
    

PARAMETERS
    -Manifest <Object>
        The [Manifest] object.
        
        Required?                    true
        Position?                    2
        Default value                
        Accept pipeline input?       true (ByValue)
        Accept wildcard characters?  false
        
    -Branch <String>
        The source control branch. The value provided will be used to determine the version 
        suffix. If not set 'git branch' will be used as default.
        
        Required?                    false
        Position?                    1
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -Major [<SwitchParameter>]
        Determines whether the 'Major' version number should be incremented.
        
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -Minor [<SwitchParameter>]
        Determines whether the 'Minor' version number should be incremented.
        
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -Patch [<SwitchParameter>]
        Determines whether the 'Patch' version number should be incremented.
        
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -DoNotSave [<SwitchParameter>]
        Determines whether to not save the modified [Manifest] object to disk.
        
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
    [Manifest]
    
    
OUTPUTS
    [Version]
    
    
    -------------------------- EXAMPLE 1 --------------------------
    
    PS C:\>$version = Get-NcrementManifest | Step-NcrementVersionNumber -Minor;
    
    
    
    
    
    
    -------------------------- EXAMPLE 2 --------------------------
    
    PS C:\>$version = Get-NcrementManifest | Step-NcrementVersionNumber "master" -Patch;
    
    
    
    
    
    
    
RELATED LINKS
    Get-NcrementManifest 
    New-NcrementManifest 
    Save-NcrementManifest 





