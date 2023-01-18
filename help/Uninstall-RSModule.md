
NAME
    Uninstall-RSModule
    
SYNOPSIS
    Uninstall older versions of your modules in a easy way.
    
    
SYNTAX
    Uninstall-RSModule [[-Module] <String[]>] [-WhatIf] [-Confirm] [<CommonParameters>]
    
    
DESCRIPTION
    This script let users uninstall older versions of the modules that are installed on the system.
    

PARAMETERS
    -Module <String[]>
        Specify modules that you want to uninstall older versions from, if this is left empty all of the older versions of the systems modules will be uninstalled
        
        Required?                    false
        Position?                    1
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -WhatIf [<SwitchParameter>]
        
        Required?                    false
        Position?                    named
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -Confirm [<SwitchParameter>]
        
        Required?                    false
        Position?                    named
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see
        about_CommonParameters (https://go.microsoft.com/fwlink/?LinkID=113216). 
    
INPUTS
    
OUTPUTS
    
NOTES
    
    
        Author:         Robin Stolpe
        Mail:           robin@stolpe.io
        Twitter:        https://twitter.com/rstolpes
        Linkedin:       https://www.linkedin.com/in/rstolpe/
        Website/Blog:   https://stolpe.io
        GitHub:         https://github.com/rstolpe
        PSGallery:      https://www.powershellgallery.com/profiles/rstolpe
    
    -------------------------- EXAMPLE 1 --------------------------
    
    PS > Uninstall-RSModule -Module "VMWare.PowerCLI"
    # This will uninstall all older versions of the module VMWare.PowerCLI system.
    
    
    
    
    
    
    -------------------------- EXAMPLE 2 --------------------------
    
    PS > Uninstall-RSModule -Module "VMWare.PowerCLI", "ImportExcel"
    # This will uninstall all older versions of VMWare.PowerCLI and ImportExcel from the system.
    
    
    
    
    
    
    
RELATED LINKS
    https://github.com/rstolpe/MaintainModule/blob/main/README.md


