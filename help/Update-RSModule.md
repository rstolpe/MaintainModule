
NAME
    Update-RSModule
    
SYNOPSIS
    This module let you maintain your installed modules in a easy way.
    
    
SYNTAX
    Update-RSModule [[-Module] <String[]>] [[-Scope] <String>] [-ImportModule] [-UninstallOldVersion] [-InstallMissing] [-WhatIf] [-Confirm] [<CommonParameters>]
    
    
DESCRIPTION
    This function let you update all of your installed modules and also uninstall the old versions to keep things clean.
    You can also specify module or modules that you want to update. It's also possible to install the module if it's missing and import the modules in the end of the script.
    

PARAMETERS
    -Module <String[]>
        Specify the module or modules that you want to update, if you don't specify any module all installed modules are updated
        
        Required?                    false
        Position?                    1
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -Scope <String>
        Need to specify scope of the installation/update for the module, either AllUsers or CurrentUser. Default is CurrentUser.
        If this parameter is empty it will use CurrentUser
        The parameter -Scope don't effect the uninstall-module function this is because of limitation from Microsoft.
        - Scope effect Install/update module function.
        
        Required?                    false
        Position?                    2
        Default value                CurrentUser
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -ImportModule [<SwitchParameter>]
        If this switch are used the module will import all the modules that are specified in the Module parameter at the end of the script.
        This only works if you have specified modules in the Module parameter
        
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -UninstallOldVersion [<SwitchParameter>]
        If this switch are used all of the old versions of your modules will get uninstalled and only the current version will be installed
        
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -InstallMissing [<SwitchParameter>]
        If you use this switch and the modules that are specified in the Module parameter are not installed on the system they will be installed.
        
        Required?                    false
        Position?                    named
        Default value                False
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
    
    PS > Update-RSModule -Module "PowerCLI", "ImportExcel" -Scope CurrentUser
    # This will update the modules PowerCLI, ImportExcel for the current user
    
    
    
    
    
    
    -------------------------- EXAMPLE 2 --------------------------
    
    PS > Update-RSModule -Module "PowerCLI", "ImportExcel" -UninstallOldVersion
    # This will update the modules PowerCLI, ImportExcel and delete all of the old versions that are installed of PowerCLI, ImportExcel.
    
    
    
    
    
    
    -------------------------- EXAMPLE 3 --------------------------
    
    PS > Update-RSModule -Module "PowerCLI", "ImportExcel" -InstallMissing
    # This will install the modules PowerCLI and/or ImportExcel on the system if they are missing, if the modules are installed already they will only get updated.
    
    
    
    
    
    
    -------------------------- EXAMPLE 4 --------------------------
    
    PS > Update-RSModule -Module "PowerCLI", "ImportExcel" -UninstallOldVersion -ImportModule
    # This will update the modules PowerCLI and ImportExcel and delete all of the old versions that are installed of PowerCLI and ImportExcel and then import the modules.
    
    
    
    
    
    
    
RELATED LINKS
    https://github.com/rstolpe/MaintainModule/blob/main/README.md


