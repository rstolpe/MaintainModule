<#
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

Function Update-MModule {
    <#
        .SYNOPSIS
        This module let you maintain your installed modules in a easy way.

        .DESCRIPTION
        With this module you can update all of your installed modules in a easy way. You can also choose to delete all of the old versions that are installed of your modules
        and only keep the current version. This module will also make sure that you are using TLS 1.2 and that PSGallery are set to trusted.

        .PARAMETER Module
        Specify the module or modules that you want to update, if you don't specify any module all installed modules are updated

        .PARAMETER ImportModule
        If this switch are used the module will import all the modules that are specified in the Module parameter at the end of the script

        .PARAMETER DeleteOldVersion
        If this switch are used all of the old versions of your modules will get uninstalled and only the current version will be installed

        .EXAMPLE
        # This will update the modules PowerCLI, ImportExcel
        Update-MModule -Module "PowerCLI, ImportExcel"

        .EXAMPLE
        # This will update the modules PowerCLI, ImportExcel and delete all of the old versions that are installed of PowerCLI, ImportExcel.
        Update-MModule -Module "PowerCLI, ImportExcel" -DeleteOldVersion

        .EXAMPLE
        # This will update the modules PowerCLI and ImportExcel and delete all of the old versions that are installed of PowerCLI and ImportExcel and then import the modules.
        Update-MModule -Module "PowerCLI, ImportExcel" -DeleteOldVersion -ImportModule

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
        [Parameter(Mandatory = $false, HelpMessage = "Specify module or modules that you want to update or install, if this is empty all installed modules will be updated")]
        [string]$Module,
        [Parameter(Mandatory = $false, HelpMessage = "Use this switch if you want to import all modules that are specified in Module parameter")]
        [switch]$ImportModule = $false,
        [Parameter(Mandatory = $false, HelpMessage = "Use this switch if you want to delete all old versions that are installed of the modules")]
        [switch]$DeleteOldVersion = $false
    )

    Write-Host "`n=== Making sure that all modules up to date ===`n"
    Write-Host "Please wait, this can take some time..."

    # Collect all installed modules from the system
    $InstalledModules = Get-InstalledModule | Select-Object Name, Version | Sort-Object Name

    # If Module parameter is empty populate it with all modules that are installed on the system
    if ($Null -eq $Module) {
        $Module = $InstalledModules.Name
    }

    # Making sure that TLS 1.2 is used.
    Write-Host "Making sure that TLS 1.2 is used..."
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

    # Checking if PSGallery are set to trusted
    if ((Get-PSRepository -name PSGallery | Select-Object InstallationPolicy -ExpandProperty InstallationPolicy) -eq "Untrusted") {
        try {
            Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
            Write-Host "PSGallery is now set to trusted!" -ForegroundColor Green
        }
        catch {
            Write-Error "$($PSItem.Exception)"
            continue
        }
    }

    # Checks if all modules in $Module are installed and up to date.
    foreach ($m in $Module.Split(",").Trim()) {
        if ($m -in $InstalledModules.Name) {
            # Collects the latest version of module
            $CollectLatestVersion = Find-Module -Name $m | Sort-Object Version -Descending | Select-Object Version -First 1

            # Get all the installed modules and versions
            $GetAllInstalledVersions = Get-InstalledModule -Name $m -AllVersions | Sort-Object PublishedDate -Descending

            Write-Host "Checking if $($m) needs to be updated..."
            # Check if the module are up to date
            if ($GetAllInstalledVersions.Version -lt $CollectLatestVersion.Version) {
                try {
                    Write-Host "Updating $($m) to version $($CollectLatestVersion.Version)..."
                    Update-Module -Name $($m) -Scope AllUsers -Force
                    Write-Host "$($m) has been updated!" -ForegroundColor Green
                }
                catch {
                    Write-Error "$($PSItem.Exception)"
                    continue
                }
                if ($DeleteOldVersion -eq $true) {
                    $GetAllInstalledVersions = Get-InstalledModule -Name $m -AllVersions | Sort-Object PublishedDate -Descending
                    # Remove old versions of the modules
                    if ($GetAllInstalledVersions.Count -gt 1) {
                        $MostRecentVersion = $GetAllInstalledVersions[0].Version
                        Foreach ($Version in $GetAllInstalledVersions.Version) {
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
            Write-Warning "$($m) module are not installed, can't update it!"
        }
    }
    if ($ImportModule -eq $true) {
        # Collect all of the imported modules.
        $ImportedModules = Get-Module | Select-Object Name, Version
    
        # Import module if it's not imported
        foreach ($m in $Module.Split(",").Trim()) {
            if ($m -in $ImportedModules.Name) {
                Write-Host "$($m) are already imported!" -ForegroundColor Green
            }
            else {
                try {
                    Write-Host "Importing $($m) module..."
                    Import-Module -Name $m -Force
                    Write-Host "$($m) are now imported!" -ForegroundColor Green
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