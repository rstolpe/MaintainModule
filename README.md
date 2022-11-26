# MaintainModule
This module let you update all of your installed modules and also uninstall the old versions to keep things clean.
You can also specify module or modules that you want to update. It's also possible to install the module if it's missing and import the modules in the end of the script.

## This module can do the following
- Checks so TLS 1.2 are used by PowerShell
- Making sure that PSGallery are set as trusted
- Update all modules that are installed on the system
- Update specified modules
- Uninstall old versions of the modules
- If specified module are missing you can choose to install it
- Import specified modules in the end of the script

# Install
Install for current user
```
Install-Module -Name MaintainModule -Scope CurrentUser -Force
```
  
Install for all users
```
Install-Module -Name MaintainModule -Scope AllUsers -Force
```

# Help
## Notes
The parameter -Scope don't effect the uninstall-module function this is because of limitation from Microsoft.  
-Scope effect Install/update module function.
## Update-RSModule
### Update all modules that are installed on the system
You can do that if you run the command.  
````
Update-RSModule
````
You can also use the -Scope parameter if you want to change from CurrentUser to AllUsers, for example ```-Scope "AllUser"```  
If -Scope parameter are empty it will set it as CurrentUser as default.

### Update specific module
If you want you can update specific modules, you can do that with the following command.  
````
Update-RSModule -Module "VMWare.PowerCLI"
````
The parameter Module has support for multiple inputs, separate them with , for example ```-Module "ImportExcel, VMWare.PowerCLI"```  
You can also use the -Scope parameter if you want to change from CurrentUser to AllUsers, for example ```-Scope "AllUser"```  
If -Scope parameter are empty it will set it as CurrentUser as default.

### Uninstall old versions of all modules
If you want to uninstall all of the old versions for all of your modules that you have installed
````
Update-RSModule -UninstallOldVersion
````
You can also use the -Scope parameter if you want to change from CurrentUser to AllUsers, for example ```-Scope "AllUser"```  
If -Scope parameter are empty it will set it as CurrentUser as default.


### Uninstall old versions of a specific module only
If you want to uninstall old versions of only a specific module you can run
````
Update-RSModule -Module "ImportExcel" -UninstallOldVersion
````
The parameter Module has support for multiple inputs, separate them with , for example ```-Module "ImportExcel, VMWare.PowerCLI"```
You can also use the -Scope parameter if you want to change from CurrentUser to AllUsers, for example ```-Scope "AllUser"```  
If -Scope parameter are empty it will set it as CurrentUser as default.

### Install missing module or modules
It's possible to install modules if they are not installed on the system, this only works if you have specified module or modules in the Module parameter.  
If the module are installed already this will not have any effect and the module will only get updated.
````
Update-RSModule -Module "VMWare.PowerCLI" -InstallMissing
````
The parameter Module has support for multiple inputs, separate them with , for example ```-Module "ImportExcel, VMWare.PowerCLI"```
You can also use the -Scope parameter if you want to change from CurrentUser to AllUsers, for example ```-Scope "AllUser"```  
If -Scope parameter are empty it will set it as CurrentUser as default.

### Import modules in the end of the script
You can choose to import all of the modules at the end of the script, this only works if you have specified module or modules in the Module parameter.
````
Update-RSModule -Module "VMWare.PowerCLI" -ImportModule
````
The parameter Module has support for multiple inputs, separate them with , for example ```-Module "ImportExcel, VMWare.PowerCLI"```
You can also use the -Scope parameter if you want to change from CurrentUser to AllUsers, for example ```-Scope "AllUser"```  
If -Scope parameter are empty it will set it as CurrentUser as default.

## Uninstall-RSModule
This function let you uninstall all of the older versions of your module or modules.
### Uninstall all older version from all of your modules
You can uninstall all of the older versions from one or more specific modules.
````
Uninstall-RSModule
````

### Uninstall all older versions from a specific module
If you want to uninstall all older version of a specific module
````
Uninstall-RSModule -Module "ImportExcel"
````
The parameter Module has support for multiple inputs, separate them with , for example ```-Module "ImportExcel, VMWare.PowerCLI"```