
NAME
    Update-RSModule
    
SYNTAX
    Update-RSModule [[-Module] <string>] [-Scope] {CurrentUser | AllUsers} [-ImportModule] [-UninstallOldVersion] [-InstallMissing] [<CommonParameters>]
    
    
PARAMETERS
    -ImportModule
        Imports all of the modules that are specified in the Module parameter in the end of the script
        
        Required?                    false
        Position?                    Named
        Accept pipeline input?       false
        Parameter set name           (All)
        Aliases                      None
        Dynamic?                     false
        Accept wildcard characters?  false
        
    -InstallMissing
        When using this switch all modules that are specified in the Module parameter and are not installed will be installed
        
        Required?                    false
        Position?                    Named
        Accept pipeline input?       false
        Parameter set name           (All)
        Aliases                      None
        Dynamic?                     false
        Accept wildcard characters?  false
        
    -Module <string>
        Specify modules that you want to update, if this is empty all of the modules that are installed on the system will get updated
        
        Required?                    false
        Position?                    0
        Accept pipeline input?       false
        Parameter set name           (All)
        Aliases                      None
        Dynamic?                     false
        Accept wildcard characters?  false
        
    -Scope <string>
        Choose either AllUsers or CurrentUser depending on which layer you want to update/Install/uninstall the module on
        
        Required?                    true
        Position?                    1
        Accept pipeline input?       false
        Parameter set name           (All)
        Aliases                      None
        Dynamic?                     false
        Accept wildcard characters?  false
        
    -UninstallOldVersion
        Uninstalls all old versions of the modules
        
        Required?                    false
        Position?                    Named
        Accept pipeline input?       false
        Parameter set name           (All)
        Aliases                      None
        Dynamic?                     false
        Accept wildcard characters?  false
        
    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see
        about_CommonParameters (https://go.microsoft.com/fwlink/?LinkID=113216). 
    
    
INPUTS
    None
    
    
OUTPUTS
    System.Object
    
ALIASES
    None
    

REMARKS
    Get-Help cannot find the Help files for this cmdlet on this computer. It is displaying only partial help.
        -- To download and install Help files for the module that includes this cmdlet, use Update-Help.


