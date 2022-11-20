﻿<#
    Copyright (C) 2022  Robin Stolpe
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

Function Confirm-NeededModules {
    <#
        .SYNOPSIS
        Module that will let you in a easy way install or upgrade needed modules and also uninstall the old version of the modules.

        .DESCRIPTION
        This function will install specified modules if they are missing or upgrade them to the latest version if the modules already are installed.
        Option to delete all of the older versions of the modules and import the modules at the end does also exist.

        .PARAMETER NeededModules
        Here you can specify what modules you want to install and upgrade

        .PARAMETER ImportModules
        If this is used it will import all of the modules in the end of the script

        .PARAMETER DeleteOldVersion
        When this is used it will delete all of the older versions of the module after upgrading the module

        .PARAMETER OnlyUpgrade
        When this is used the script will not install any modules it will upgrade all of the already installed modules on the computer to the latest version.

        .EXAMPLE
        # This will check so PowerCLI and ImportExcel is installd and up to date, it not it will install them or upgrade them to the latest version and then delete all of the old versions and import the modules.
        Confirm-NeededModules -NeededModules "PowerCLI,ImportExcel" -ImportModules -DeleteOldVersion

        .EXAMPLE
        # This will only install PowerCli if it's not installed and upgrade it if needed. This example will not delete the old versions of PowerCli or import the module at the end.
        Confirm-NeededModules -NeededModules "PowerCLI"

        .EXAMPLE
        # This will only upgrade PowerCLI module
        Confirm-NeededModules -NeededModules "PowerCLI" -OnlyUpgrade

        .EXAMPLE
        # This will upgrade all of the already installed modules on the computer to the latest version
        Confirm-NeededModules -OnlyUpgrade

        .EXAMPLE
        # This will upgrade all of the already installed modules on the computer to the latest version and delete all of the old versions after
        Confirm-NeededModules -OnlyUpgrade -DeleteOldVersion

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
        [array]$NeededModules,
        [switch]$ImportModules,
        [switch]$DeleteOldVersion,
        [switch]$OnlyUpgrade
    )
    # Collects all of the installed modules on the system
    $CurrentModules = Get-InstalledModule | Select-Object Name, Version | Sort-Object Name

    if ($OnlyUpgrade -eq $True) {
        if ($Null -eq $NeededModules) {
            $NeededModules = $CurrentModules.Name
        }
        $HeadLine = "`n=== Making sure that all modules up to date ===`n"
    }
    else {
        $HeadLine = "`n=== Making sure that all modules are installad and up to date ===`n"
        $NeededPackages = @("NuGet", "PowerShellGet")
        # Collects all of the installed packages
        $CurrentInstalledPackageProviders = Get-PackageProvider -ListAvailable | Select-Object Name -ExpandProperty Name
    }

    Write-Host $HeadLine
    Write-Host "Please wait, this can take time..."
    # This packages are needed for this script to work, you can add more if you want. Don't confuse this with modules
    if ($OnlyUpgrade -eq $false) {
        # Making sure that TLS 1.2 is used.
        Write-Host "Making sure that TLS 1.2 is used..."
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

        # Installing needed packages if it's missing.
        Write-Host "Making sure that all of the Package providers that are needed are installed..."
        foreach ($Provider in $NeededPackages) {
            if ($Provider -NotIn $CurrentInstalledPackageProviders) {
                Try {
                    Write-Host "Installing $($Provider) as it's missing..."
                    Install-PackageProvider -Name $provider -Force -Scope AllUsers
                    Write-Host "$($Provider) is now installed" -ForegroundColor Green
                }
                catch {
                    Write-Error "$($PSItem.Exception)"
                    continue
                }
            }
            else {
                Write-Host "$($provider) is already installed." -ForegroundColor Green
            }
        }

        # Setting PSGallery as trusted if it's not trusted
        Write-Host "Making sure that PSGallery is set to Trusted..."
        if ((Get-PSRepository -name PSGallery | Select-Object InstallationPolicy -ExpandProperty InstallationPolicy) -eq "Untrusted") {
            try {
                Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
                Write-Host "PSGallery is now set to trusted" -ForegroundColor Green
            }
            catch {
                Write-Error "$($PSItem.Exception)"
                continue
            }
        }
        else {
            Write-Host "PSGallery is already trusted" -ForegroundColor Green
        }
    }

    # Checks if all modules in $NeededModules are installed and up to date.
    foreach ($m in $NeededModules.Split(",").Trim()) {
        if ($m -in $CurrentModules.Name -or $OnlyUpgrade -eq $true) {
            if ($m -in $CurrentModules.Name) {
                # Collects the latest version of module
                $NewestVersion = Find-Module -Name $m | Sort-Object Version -Descending | Select-Object Version -First 1
                # Get all the installed modules and versions
                $AllCurrentVersion = Get-InstalledModule -Name $m -AllVersions | Sort-Object PublishedDate -Descending

                Write-Host "Checking if $($m) needs to be updated..."
                # Check if the module are up to date
                if ($AllCurrentVersion.Version -lt $NewestVersion.Version) {
                    try {
                        Write-Host "Updating $($m) to version $($NewestVersion.Version)..."
                        Update-Module -Name $($m) -Scope AllUsers -Force
                        Write-Host "$($m) has been updated!" -ForegroundColor Green
                    }
                    catch {
                        Write-Error "$($PSItem.Exception)"
                        continue
                    }
                    if ($DeleteOldVersion -eq $true) {
                        $AllCurrentVersion = Get-InstalledModule -Name $m -AllVersions | Sort-Object PublishedDate -Descending
                        # Remove old versions of the modules
                        if ($AllCurrentVersion.Count -gt 1) {
                            $MostRecentVersion = $AllCurrentVersion[0].Version
                            Foreach ($Version in $AllCurrentVersion.Version) {
                                if ($Version -ne $MostRecentVersion) {
                                    try {
                                        Write-Host "Uninstalling previous version $($Version) of module $($m)..."
                                        Uninstall-Module -Name $m -RequiredVersion $Version -Force -ErrorAction SilentlyContinue
                                        Write-Host "Version $($Version) of $($m) are now uninstalled!" -ForegroundColor Green
                                    }
                                    catch {
                                        Write-Error "$($PSItem.Exception)"
                                        continue
                                    }
                                }
                            }
                        }
                    }
                }
                else {
                    Write-Host "$($m) don't need to be updated as it's on the latest version" -ForegroundColor Green
                }
            }
            else {
                Write-Warning "Can't check if $($m) needs to be updated as $($m) are not installed!"
            }
        }
        else {
            # Installing missing module
            Write-Host "Installing module $($m) as it's missing..."
            try {
                Install-Module -Name $m -Scope AllUsers -Force
                Write-Host "$($m) are now installed!" -ForegroundColor Green
            }
            catch {
                Write-Error "$($PSItem.Exception)"
                continue
            }
        }
    }
    if ($ImportModules -eq $true) {
        # Collect all of the imported modules.
        $ImportedModules = get-module | Select-Object Name, Version
    
        # Import module if it's not imported
        foreach ($module in $NeededModules.Split(",").Trim()) {
            if ($module -in $ImportedModules.Name) {
                Write-Host "$($Module) are already imported!" -ForegroundColor Green
            }
            else {
                try {
                    Write-Host "Importing $($module) module..."
                    Import-Module -Name $module -Force
                    Write-Host "$($module) are now imported!" -ForegroundColor Green
                }
                catch {
                    Write-Error "$($PSItem.Exception)"
                    continue
                }
            }
        }
    }
    Write-Host "`n== Script Finished! ==" -ForegroundColor Green
}