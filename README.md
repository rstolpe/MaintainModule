![GitHub](https://img.shields.io/github/license/rstolpe/MaintainModule?style=plastic)  
![GitHub release (latest SemVer)](https://img.shields.io/github/v/release/rstolpe/MaintainModule?sort=semver&style=plastic)  ![Last release](https://img.shields.io/github/release-date/rstolpe/MaintainModule?style=plastic)
![GitHub last commit](https://img.shields.io/github/last-commit/rstolpe/MaintainModule?style=plastic)  
![PSGallery downloads](https://img.shields.io/powershellgallery/dt/MaintainModule?style=plastic)
  
# MaintainModule
This module let you update all of your installed modules and also uninstall the old versions to keep things clean.  
You can also specify module or modules that you want to update. It's also possible to install the module if it's missing and import the modules in the end of the script.  
Works on all OS versions.

## This module can do the following
- Checks so TLS 1.2 are used by PowerShell
- Making sure that PSGallery are set as trusted
- Update all modules that are installed on the system
- Update specified modules
- Uninstall old versions of the modules
- If specified module are missing you can choose to install it
- Ignore SkipPublisherCheck
- Update / install Pre-release

## Dependencies
- Module also require that you have my service module installed, [rsServiceModule](https://github.com/rstolpe/rsServiceModule)

# Links
* [My PowerShell Collection](https://github.com/rstolpe/PSCollection)
* [Webpage/Blog](https://www.stolpe.io)
* [Twitter](https://twitter.com/rstolpes)
* [LinkedIn](https://www.linkedin.com/in/rstolpe/)
* [PowerShell Gallery](https://www.powershellgallery.com/profiles/rstolpe)


## Notes
The parameter -Scope don't effect the uninstall-module function this is because of limitation from Microsoft.  
-Scope effect Install/update module function.

## Install
Install for current user
```
Install-Module -Name MaintainModule -Scope CurrentUser -Force
```
  
Install for all users
```
Install-Module -Name MaintainModule -Scope AllUsers -Force
```

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
The parameter Module has support for multiple inputs, separate them with , for example ```-Module "ImportExcel", "VMWare.PowerCLI"```  
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
The parameter Module has support for multiple inputs, separate them with , for example ```-Module "ImportExcel", "VMWare.PowerCLI"```
You can also use the -Scope parameter if you want to change from CurrentUser to AllUsers, for example ```-Scope "AllUser"```  
If -Scope parameter are empty it will set it as CurrentUser as default.

### Install missing module or modules
It's possible to install modules if they are not installed on the system, this only works if you have specified module or modules in the Module parameter.  
If the module are installed already this will not have any effect and the module will only get updated.
````
Update-RSModule -Module "VMWare.PowerCLI" -InstallMissing
````
The parameter Module has support for multiple inputs, separate them with , for example ```-Module "ImportExcel", "VMWare.PowerCLI"```
You can also use the -Scope parameter if you want to change from CurrentUser to AllUsers, for example ```-Scope "AllUser"```  
If -Scope parameter are empty it will set it as CurrentUser as default.

### Allow pre-release
If you want to allow pre-releases simply add ```-AllowPrerelease $true````

### SkipPublisherCheck
If you for some reason want to skip publisher check add ```-SkipPublisherCheck $true``` this is needed for Pester and PowerCLI for an example