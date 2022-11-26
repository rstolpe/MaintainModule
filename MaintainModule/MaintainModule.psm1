<#
    Copyright (C) 2022 Robin Stolpe.
    <https://stolpe.io>
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
    #>
#
#
Function Uninstall-RSModule {
    <#
        .SYNOPSIS
        Uninstall older versions of your modules in a easy way.

        .DESCRIPTION
        This script let users uninstall older versions of the modules that are installed on the system.

        .PARAMETER Module
        Specify modules that you want to uninstall older versions from, if this is left empty all of the older versions of the systems modules will be uninstalled

        .EXAMPLE
        Uninstall-RSModule -Module "VMWare.PowerCLI"
        # This will uninstall all older versions of the module VMWare.PowerCLI system.

        .EXAMPLE
        Uninstall-RSModule -Module "VMWare.PowerCLI, ImportExcel"
        # This will uninstall all older versions of VMWare.PowerCLI and ImportExcel from the system.

        .RELATED LINKS
        https://github.com/rstolpe/MaintainModule/blob/main/README.md

        .NOTES
        Author:     Robin Stolpe
        Mail:       robin@stolpe.io
        Website:	https://stolpe.io
        GitHub:		https://github.com/rstolpe
        Twitter:	https://twitter.com/rstolpes
        PSGallery:	https://www.powershellgallery.com/profiles/rstolpe
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false, HelpMessage = "Enter the module or modules (separated with ,) you want to uninstall")]
        [string]$Module
    )

    Write-Output "`n=== Starting to uninstall older versions of modules ===`n"
    Write-Output "Please wait, this can take some time..."

    # Collect all installed modules from the system
    Write-Verbose "Caching all installed modules from the system..."
    $InstalledModules = Get-InstalledModule | Select-Object Name, Version | Sort-Object Name

    # If Module parameter is empty populate it with all modules that are installed on the system
    if ([string]::IsNullOrEmpty($Module)) {
        Write-Verbose "Parameter Module are empty populate it with all installed modules from the system..."
        $Module = $InstalledModules.Name
    }
    else {
        Write-Verbose "User has added modules to the Module parameter, splitting them"
        $Module = $Module.Split(",").Trim()
    }

    foreach ($m in $Module.Split()) {
        Write-Verbose "Collecting all installed version of the module $($m)"
        $GetAllInstalledVersions = Get-InstalledModule -Name $m -AllVersions | Sort-Object PublishedDate -Descending

        # If the module has more then one version loop trough the versions and only keep the most current one
        if ($GetAllInstalledVersions.Count -gt 1) {
            $MostRecentVersion = $GetAllInstalledVersions[0].Version
            Foreach ($Version in $GetAllInstalledVersions.Version) {
                if ($Version -ne $MostRecentVersion) {
                    try {
                        Write-Output "Uninstalling previous version $($Version) of module $($m)..."
                        Uninstall-Module -Name $m -RequiredVersion $Version -Force -ErrorAction SilentlyContinue
                        Write-Output "Version $($Version) of $($m) are now uninstalled!"
                    }
                    catch {
                        Write-Error "$($PSItem.Exception)"
                        continue
                    }
                }
            }
            Write-Output "All older versions of $($m) are now uninstalled, the only installed version of $($m) is $($MostRecentVersion)"
        }
        else {
            Write-Verbose "$($m) don't have any older versions installed then the most current one, no need to uninstall anything."
        }
    }
    Write-Output "`n---/// Script Finished! ///---"
}
Function Update-RSModule {
    <#        
        .SYNOPSIS
        This module let you maintain your installed modules in a easy way.

        .DESCRIPTION
        This function let you update all of your installed modules and also uninstall the old versions to keep things clean.
        You can also specify module or modules that you want to update. It's also possible to install the module if it's missing and import the modules in the end of the script.

        .PARAMETER Module
        Specify the module or modules that you want to update, if you don't specify any module all installed modules are updated

        .PARAMETER Scope
        Need to specify scope of the installation/update for the module, either AllUsers or CurrentUser. Default is CurrentUser.
        If this parameter is empty it will use CurrentUser
        The parameter -Scope don't effect the uninstall-module function this is because of limitation from Microsoft.  
        - Scope effect Install/update module function.

        .PARAMETER ImportModule
        If this switch are used the module will import all the modules that are specified in the Module parameter at the end of the script.
        This only works if you have specified modules in the Module parameter

        .PARAMETER UninstallOldVersion
        If this switch are used all of the old versions of your modules will get uninstalled and only the current version will be installed

        .PARAMETER InstallMissing
        If you use this switch and the modules that are specified in the Module parameter are not installed on the system they will be installed.

        .EXAMPLE
        Update-RSModule -Module "PowerCLI, ImportExcel" -Scope CurrentUser
        # This will update the modules PowerCLI, ImportExcel for the current user

        .EXAMPLE
        Update-RSModule -Module "PowerCLI, ImportExcel" -UninstallOldVersion
        # This will update the modules PowerCLI, ImportExcel and delete all of the old versions that are installed of PowerCLI, ImportExcel.

        .EXAMPLE
        Update-RSModule -Module "PowerCLI, ImportExcel" -InstallMissing
        # This will install the modules PowerCLI and/or ImportExcel on the system if they are missing, if the modules are installed already they will only get updated.

        .EXAMPLE
        Update-RSModule -Module "PowerCLI, ImportExcel" -UninstallOldVersion -ImportModule
        # This will update the modules PowerCLI and ImportExcel and delete all of the old versions that are installed of PowerCLI and ImportExcel and then import the modules.

        .RELATED LINKS
        https://github.com/rstolpe/MaintainModule/blob/main/README.md

        .NOTES
        Author:     Robin Stolpe
        Mail:       robin@stolpe.io
        Twitter:    @rstolpes
        Website:    https://stolpe.io
        GitHub:     https://github.com/rstolpe
        PSGallery:  https://www.powershellgallery.com/profiles/rstolpe
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false, HelpMessage = "Enter module or modules (separated with ,) that you want to update, if you don't enter any all of the modules will be updated")]
        [string]$Module,
        [ValidateSet("CurrentUser", "AllUsers")] 
        [Parameter(Mandatory = $true, HelpMessage = "Enter CurrentUser or AllUsers depending on what scope you want to change your modules")]
        [string]$Scope = "CurrentUser",
        [Parameter(Mandatory = $false, HelpMessage = "Import modules that has been entered in the module parameter at the end of this function")]
        [switch]$ImportModule = $false,
        [Parameter(Mandatory = $false, HelpMessage = "Uninstalls all old versions of the modules")]
        [switch]$UninstallOldVersion = $false,
        [Parameter(Mandatory = $false, HelpMessage = "Install all of the modules that has been entered in module that are not installed on the system")]
        [switch]$InstallMissing = $false
    )

    Write-Output "`n=== Starting module maintenance ===`n"
    Write-Output "Please wait, this can take some time..."

    # Collect all installed modules from the system
    Write-Verbose "Caching all installed modules from the system..."
    $InstalledModules = Get-InstalledModule | Select-Object Name, Version | Sort-Object Name
    $EmptyModule = $false

    # If Module parameter is empty populate it with all modules that are installed on the system
    if ([string]::IsNullOrEmpty($Module)) {
        Write-Verbose "Parameter Module are empty populate it with all installed modules from the system..."
        $EmptyModule = $true
        $Module = $InstalledModules.Name
    }
    else {
        Write-Verbose "User has added modules to the Module parameter, splitting them"
        $Module = $Module.Split(",").Trim()
    }

    # Making sure that TLS 1.2 is used.
    Write-Verbose "Making sure that TLS 1.2 is used..."
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

    # Checking if PSGallery are set to trusted
    Write-Verbose "Checking if PowerShell Gallery are set to trusted..."
    if ((Get-PSRepository -name PSGallery | Select-Object InstallationPolicy -ExpandProperty InstallationPolicy) -eq "Untrusted") {
        try {
            Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
            Write-Output "PowerShell Gallery was not set as trusted, it's now set as trusted!"
        }
        catch {
            Write-Error "$($PSItem.Exception)"
            continue
        }
    }
    else {
        Write-Verbose "PowerShell Gallery was already set to trusted, continuing!"
    }


    # Start looping trough every module that are stored in the string Module
    foreach ($m in $Module.Split()) {

        Write-Verbose "Checks if $($m) are installed"
        if ($m -in $InstalledModules.Name) {

            # Get all of the installed versions of the module
            Write-Verbose "Collecting all installed version of $($m)..."
            $GetAllInstalledVersions = Get-InstalledModule -Name $m -AllVersions | Sort-Object PublishedDate -Descending

            # Collects the latest version of module
            Write-Verbose "Looking up the latest version of $($m)..."
            $CollectLatestVersion = Find-Module -Name $m | Sort-Object Version -Descending | Select-Object Version -First 1

            # Looking if the version of the module are the latest version
            if ($GetAllInstalledVersions.Version -lt $CollectLatestVersion.Version) {
                try {
                    Write-Output "Found a newer version of $($m), version $($CollectLatestVersion.Version)"
                    Write-Output "Updating $($m) to version $($CollectLatestVersion.Version)..."
                    Update-Module -Name $($m) -Scope $Scope -Force
                    Write-Output "$($m) has been updated to version $($CollectLatestVersion.Version)!"
                }
                catch {
                    Write-Error "$($PSItem.Exception)"
                    continue
                }

                # If switch -UninstallOldVersion has been used then the old versions will be uninstalled from the module
                if ($UninstallOldVersion -eq $true) {
                    Uninstall-RSModule -Module $m
                }
            }
            else {
                Write-Verbose "$($m) already has the newest version installed, no need to install anything!"
            }
        }
        else {
            # If the switch InstallMissing are set to true the modules will get installed if they are missing
            if ($InstallMissing -eq $true) {
                try {
                    Write-Output "$($m) are not installed, installing $($m)..."
                    Install-Module -Name $($m) -Scope $Scope -Force
                    Write-Output "$($m) has now been installed!"
                }
                catch {
                    Write-Error "$($PSItem.Exception)"
                    continue
                }
            }
            else {
                Write-Warning "$($m) module are not installed, and you have not chosen to install missing modules. Continuing without any actions!"
            }
        }
    }
    if ($EmptyModule -eq $false) {
        if ($ImportModule -eq $true) {
            # Collect all of the imported modules.
            Write-Verbose "Collecting all of the installed modules..."
            $ImportedModules = Get-Module | Select-Object Name, Version
    
            # Import module if it's not imported
            Write-Verbose "Starting to import the modules..."
            foreach ($m in $Module.Split()) {
                if ($m -in $ImportedModules.Name) {
                    Write-Verbose "$($m) are already imported!"
                }
                else {
                    try {
                        Write-Output "Importing $($m)..."
                        Import-Module -Name $m -Force
                        Write-Output "$($m) has been imported!"
                    }
                    catch {
                        Write-Error "$($PSItem.Exception)"
                        continue
                    }
                }
            }
        }
    }
    Write-Output "`n---/// Script Finished! ///---"
}
