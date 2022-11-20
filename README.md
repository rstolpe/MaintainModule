# MaintainModule
### This module can do the following
- Checks so TLS 1.2 are used by PowerShell
- Making sure that PSGallery are set as trusted
- If the module are installed it will check if it's the latest version if not then it will update the module.
- If the module are updated the script will uninstall the old version of the module.
- If selected script will import the module in the end

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
You can also specify multiple specific module if you separate the module names with , for example ```-Module "VMWare.PowerCLI, ImportExcel"```

## Uninstall old versions
It's possible to uninstall all of the old versions of a module after the module has been updated, this works on all commands.
````
Update-MModule -Module "VMWare.PowerCLI" -UninstallOldVersion
````

