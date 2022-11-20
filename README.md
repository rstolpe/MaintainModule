# MaintainModule
### This module can do the following
- Checks so TLS 1.2 are used by PowerShell
- Making sure that NuGet and PowerShellGet are installed as provider
- Making sure that PSGallery are set as trusted
- Checks if the module are installed, if it's not installed it will be installed.
- If the module are installed it will check if it's the latest version if not then it will update the module.
- If the module are updated the script will uninstall the old version of the module.
- If selected script will import the module in the end

# Install
```
Install-Module -Name MaintainModule
```

# Examples