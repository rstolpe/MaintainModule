# MaintainModule
## This module can do the following
- Checks so TLS 1.2 are used by PowerShell
- Making sure that PSGallery are set as trusted
- Update all modules that are installed on the system
- Update specified modules
- Uninstall old versions of the modules
- If specified module are missing you can choose to install it
- Import specified modules in the end of the script

# Install
```
Install-Module -Name MaintainModule
```

# Help
## Update all modules that are installed on the system
You can do that if you run the command.  
````
Update-MModule
````

## Update specific module
If you want you can update specific modules, you can do that with the following command.  
````
Update-MModule -Module "VMWare.PowerCLI"
````
You can also specify multiple specific module if you separate the module names with , for example
````
Update-MModule -Module "VMWare.PowerCLI, ImportExcel"
````

## Uninstall old versions
It's possible to uninstall all of the old versions of a module after the module has been updated, this works on all commands.
````
Update-MModule -Module "VMWare.PowerCLI" -UninstallOldVersion
````

## Install missing module or modules
It's possible to install modules if they are not installed on the system, this only works if you have specified module or modules in the Module parameter.  
If the module are installed already this will not have any effect and the module will only get updated.
````
Update-MModule -Module "VMWare.PowerCLI" -InstallMissing
````

## Import modules in the end of the script
You can choose to import all of the modules at the end of the script, this only works if you have specified module or modules in the Module parameter.
````
Update-MModule -Module "VMWare.PowerCLI" -ImportModule
````

