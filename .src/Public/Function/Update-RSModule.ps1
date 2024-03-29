﻿Function Update-RSModule {
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
        Update-RSModule -Module "PowerCLI", "ImportExcel" -Scope CurrentUser
        # This will update the modules PowerCLI, ImportExcel for the current user

        .EXAMPLE
        Update-RSModule -Module "PowerCLI", "ImportExcel" -UninstallOldVersion
        # This will update the modules PowerCLI, ImportExcel and delete all of the old versions that are installed of PowerCLI, ImportExcel.

        .EXAMPLE
        Update-RSModule -Module "PowerCLI", "ImportExcel" -InstallMissing
        # This will install the modules PowerCLI and/or ImportExcel on the system if they are missing, if the modules are installed already they will only get updated.

        .EXAMPLE
        Update-RSModule -Module "PowerCLI", "ImportExcel" -UninstallOldVersion -ImportModule
        # This will update the modules PowerCLI and ImportExcel and delete all of the old versions that are installed of PowerCLI and ImportExcel and then import the modules.

        .LINK
        https://github.com/rstolpe/MaintainModule/blob/main/README.md

        .NOTES
        Author:         Robin Stolpe
        Mail:           robin@stolpe.io
        Twitter:        https://twitter.com/rstolpes
        Linkedin:       https://www.linkedin.com/in/rstolpe/
        Website/Blog:   https://stolpe.io
        GitHub:         https://github.com/rstolpe
        PSGallery:      https://www.powershellgallery.com/profiles/rstolpe
    #>

    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory = $false, HelpMessage = "Enter module or modules that you want to update, if you don't enter any, all of the modules will be updated")]
        [string[]]$Module,
        [Parameter(Mandatory = $false, HelpMessage = "Enter CurrentUser or AllUsers depending on what scope you want to change your modules, default is CurrentUser")]
        [ValidateSet("CurrentUser", "AllUsers")]
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
        $OldModule = $Module.Split(",").Trim()
        [System.Collections.ArrayList]$Module = @()

        if ($InstallMissing -eq $false) {
            Write-Verbose "Looking so the modules exists in the system..."
            foreach ($m in $OldModule) {
                if ($m -in $InstalledModules.name) {
                    Write-Verbose "$($m) did exists in the system..."
                    [void]($Module.Add($m))
                }
                else {
                    Write-Warning "$($m) did not exists in the system, skipping this module..."
                }
            }
        }
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
    foreach ($m in $Module) {
        Write-Verbose "Checks if $($m) are installed"
        if ($m -in $InstalledModules.Name) {

            # Getting the latest installed version of the module
            Write-Verbose "Collecting all installed version of $($m)..."
            $GetAllInstalledVersions = Get-InstalledModule -Name $m -AllVersions | Sort-Object { $_.Version -as [version] } -Descending | Select-Object Version
            [version]$LatestInstalledVersion = $($GetAllInstalledVersions | Select-Object Version -First 1).version

            # Collects the latest version of module from the source where the module was installed from
            Write-Verbose "Looking up the latest version of $($m)..."
            [version]$CollectLatestVersion = $(Find-Module -Name $m -AllVersions | Sort-Object { $_.Version -as [version] } -Descending | Select-Object Version -First 1).version

            # Looking if the version of the module are the latest version, it it's not the latest it will install the latest version.
            if ($LatestInstalledVersion -lt $CollectLatestVersion) {
                try {
                    Write-Output "Found a newer version of $($m), version $($CollectLatestVersion)"
                    Write-Output "Updating $($m) from $($LatestInstalledVersion) to version $($CollectLatestVersion)..."
                    Update-Module -Name $($m) -Scope $Scope -Force
                    Write-Output "$($m) has now been updated to version $($CollectLatestVersion)!`n"
                }
                catch {
                    Write-Error "$($PSItem.Exception)"
                    continue
                }
            }

            # If switch -UninstallOldVersion has been used then the old versions will be uninstalled from the module
            if ($UninstallOldVersion -eq $true) {
                if ($GetAllInstalledVersions.Count -gt 1) {
                    Write-Output "Uninstalling old versions $($LatestInstalledVersion) of $($m)..."
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
            foreach ($m in $Module) {
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
    Write-Output "`n=== \\\ Script Finished! /// ===`n"
}