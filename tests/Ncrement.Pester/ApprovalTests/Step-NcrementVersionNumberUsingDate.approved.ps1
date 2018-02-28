
NAME
    Step-NcrementVersionNumberUsingDate
    
SYNOPSIS
    Increments the specified [Manifest] version number using the [DateTime]::UtcNow.
    
    
SYNTAX
    Step-NcrementVersionNumberUsingDate [-Manifest] <Object> [[-Major] <String>] [[-Minor] 
    <String>] [[-Patch] <String>] [[-Branch] <String>] [-DoNotSave] [<CommonParameters>]
    
    
DESCRIPTION
    This function increments the [Manifest] version number using the [DateTime]::UtcNow 
    object. If values passed to the 'Major', 'Minor' and 'Patch' parameters are not intergers, 
    the their values will be used as format strings for the [DateTime]::ToString method. Also 
    when invoked, the version will be incremented then the modified [Manifest] object will be 
    saved to disk as well.
    

PARAMETERS
    -Manifest <Object>
        The [Manifest] object.
        
        Required?                    true
        Position?                    5
        Default value                
        Accept pipeline input?       true (ByValue)
        Accept wildcard characters?  false
        
    -Major <String>
        The major version number. Accpets  Defaults to 'yyMM'.
        
        Required?                    false
        Position?                    1
        Default value                yyMM
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -Minor <String>
        The minor version number. Defaults to 'ddHH'.
        
        Required?                    false
        Position?                    2
        Default value                ddHH
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -Patch <String>
        The patch version number. Defaults to 'Path + 1'.
        
        Required?                    false
        Position?                    3
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -Branch <String>
        The source control branch. The value provided will be used to determine the version 
        suffix. If not set 'git branch' will be used as default.
        
        Required?                    false
        Position?                    4
        Default value                
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
    [Manifest]
    
    
    -------------------------- EXAMPLE 1 --------------------------
    
    PS C:\>$version = Get-NcrementManifest | Step-NcrementVersionNumberUsingDate -Major "yyMM" 
    -Minor "ddmm";
    
    In this example, because DateTime format strings were passed, each value will be used as 
    the argument for the [DateTime]::UtcNow.ToString() method to replace their respective 
    values.
    
    
    
    
    -------------------------- EXAMPLE 2 --------------------------
    
    PS C:\>$version = Get-NcrementManifest | Step-NcrementVersionNumberUsingDate -Major "1709" 
    -Minor "1123" -Patch "4586";
    
    In this example, because integers were passed the function will return "1709.1123.4586".
    
    
    
    
    
RELATED LINKS
    Get-NcrementManifest 
    New-NcrementManifest 
    Save-NcrementManifest 





