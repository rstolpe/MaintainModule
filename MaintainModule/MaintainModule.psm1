<#
    MIT License

    Copyright (C) 2024 Robin Stolpe.

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
#>
Function Uninstall-rsModule {
    <#
        .SYNOPSIS
        Uninstall older versions of your modules in a easy way.

        .DESCRIPTION
        This script let users uninstall older versions of the modules that are installed on the system.

        .PARAMETER Module
        Specify modules that you want to uninstall older versions from, if this is left empty all of the older versions of the systems modules will be uninstalled

        .EXAMPLE
        Uninstall-rsModule -Module "VMWare.PowerCLI"
        # This will uninstall all older versions of the module VMWare.PowerCLI system.

        .EXAMPLE
        Uninstall-rsModule -Module "VMWare.PowerCLI", "ImportExcel"
        # This will uninstall all older versions of VMWare.PowerCLI and ImportExcel from the system.

        .EXAMPLE
        Uninstall-rsModule
        # This will uninstall all older versions of all modules in the system

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
        [Parameter(Mandatory = $false, HelpMessage = "Enter the module or modules you want to uninstall older version of, if not used all older versions will be uninstalled")]
        [string]$Module,
        [Parameter(Mandatory = $false, HelpMessage = ".")]
        [string[]]$OldVersion
    )

    Write-Output "START - Uninstall older versions of $($Module)"
    Write-Output "Please wait, this can take some time..."

    foreach ($_version in $OldVersion) {
        Write-Verbose "Uninstalling version $($_version) of $($Module)..."
        try {
            Uninstall-Module -Name $Module -RequiredVersion $_version -Force -ErrorAction SilentlyContinue
        }
        catch {
            Write-Error "$($PSItem.Exception)"
            continue
        }
    }
    Write-Output "FINISHED - All older versions of $($Module) are now uninstalled!"
}
Function Get-rsInstalledModule {
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory = $false, HelpMessage = "Enter module or modules that you want to update, if you don't enter any, all of the modules will be updated")]
        [string[]]$Module
    )

    $ReturnCode = 0
    $ReturnData = [ordered]@{}

    # Collect all installed modules from the system
    Write-Verbose "Caching all installed modules from the system..."
    $GetInstalledModules = Get-InstalledModule | Select-Object Name | Sort-Object -Descending

    if ([string]::IsNullOrEmpty($Module)) {
        Write-Verbose "Parameter Module are empty, populate it with all installed modules from the system..."
        $ReturnModule = foreach ($_module in $GetInstalledModules) {
            Write-Verbose "Collecting information about module $($_module)..."
            $GetAllInstalledVersions = Get-InstalledModule -Name $_module.name -AllVersions | Sort-Object { $_.Version -as [version] } -Descending

            # Get latest version
            [version]$LatestVersion = $($GetAllInstalledVersions | Select-Object Version -First 1).version

            # Get get all old versions
            [version]$OldVersions = $GetAllInstalledVersions | Where-Object { $_.Version -ne $LatestVersion } | Select-Object Version

            [PSCustomObject]@{
                Name          = $_module.Name
                Repository    = $GetAllInstalledVersions.Repository
                OldVersion    = $OldVersions
                LatestVersion = $LatestVersion
            }
        }
    }
    else {
        Write-Verbose "Looking so the modules exists in the system..."
        $ReturnModule = foreach ($_module in $Module) {
            if ($_module -in $GetInstalledModules.name) {
                Write-Verbose "$($_module) is installed, collecting information about it..."
                $GetAllInstalledVersions = Get-InstalledModule -Name $_module -AllVersions | Sort-Object { $_.Version -as [version] } -Descending

                # Get latest version
                [version]$LatestVersion = $($GetAllInstalledVersions | Select-Object Version -First 1).version

                # Get get all old versions
                [version]$OldVersions = $GetAllInstalledVersions | Where-Object { $_.Version -ne $LatestVersion } | Select-Object Version

                [PSCustomObject]@{
                    Name          = $_module
                    Repository    = $GetAllInstalledVersions.Repository
                    OldVersion    = $OldVersions
                    LatestVersion = $LatestVersion
                }
            }
            else {
                Write-Warning "$($_module) is not installed, skipping this module..."
            }
        }
    }

    if ($null -eq $ReturnModule) {
        $ReturnCode = 1
        Write-Warning "No modules was found..."
        $ReturnModule = $null
    }

    $ReturnData.Add("ReturnCode", $ReturnCode)
    $ReturnData.Add("Module", $ReturnModule)
    
    return $ReturnData
}
Function Test-rsComponent {
    [CmdletBinding(SupportsShouldProcess)]
    Param(

    )

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
}
Function Update-rsModule {
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
        Update-rsModule -Module "PowerCLI", "ImportExcel" -Scope "CurrentUser"
        # This will update the modules PowerCLI, ImportExcel for the current user

        .EXAMPLE
        Update-rsModule -Module "PowerCLI", "ImportExcel" -UninstallOldVersion
        # This will update the modules PowerCLI, ImportExcel and delete all of the old versions that are installed of PowerCLI, ImportExcel.

        .EXAMPLE
        Update-rsModule -Module "PowerCLI", "ImportExcel" -InstallMissing
        # This will install the modules PowerCLI and/or ImportExcel on the system if they are missing, if the modules are installed already they will only get updated.

        .EXAMPLE
        Update-rsModule -Module "PowerCLI", "ImportExcel" -UninstallOldVersion -ImportModule
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
        [switch]$InstallMissing = $false,
        [Parameter(Mandatory = $false, HelpMessage = "Don't check publishers certificate")]
        [switch]$SkipPublisherCheck = $false,
        [Parameter(Mandatory = $false, HelpMessage = "If this is used updates etc. be for prerelease")]
        [bool]$AllowPrerelease = $false
    )

    Write-Output "`n=== Module Maintenance - Stolpe.io 2024 ==="
    Write-Output "Please wait, this can take some time...`n"

    # Making sure that all needed components are installed
    Test-rsComponent

    Write-Output "START - Updating modules`n"

    # Collect all installed modules from the system
    $GetModuleInfo = Get-rsInstalledModule -Module $Module

    # Start looping trough every module that are stored in the string Module
    if ($GetModuleInfo.ReturnCode -eq 0) {
        foreach ($_module in $GetModuleInfo.Module) {
            # Getting the latest installed version of the module
            Write-Verbose "Collecting all installed version of $($_module.Name)..."

            # Collects the latest version of module from the source where the module was installed from
            Write-Verbose "Looking up the latest version of $($_module)..."
            [version]$CollectLatestVersion = $(Find-Module -Name $_module.Name -Repository $_module.Repository -AllVersions | Sort-Object { $_.Version -as [version] } -Descending | Select-Object Version -First 1).version

            # Looking if the version of the module are the latest version, it it's not the latest it will install the latest version.
            if ($_module.LatestVersion -lt $CollectLatestVersion) {
                try {
                    # Variable to store warnings
                    $warnings = @()

                    Write-Output "Found a newer version of $($_module.Name), version $CollectLatestVersion"
                    Write-Output "Updating $($_module.Name) from $($_module.LatestVersion) to version $CollectLatestVersion..."
                    Update-Module -Name $_module.Name -Scope $Scope -AllowPrerelease:$AllowPrerelease -AcceptLicense -Force -WarningVariable warnings -ErrorAction SilentlyContinue
                    Write-Output "$($_module.Name) has now been updated to version $CollectLatestVersion!`n"

                    if ($null -ne $warnings) {
                        # Filter warnings related to certificate issues and get module names
                        $certificateIssues = $warnings | Where-Object {
                            $_.Message -match "certificate" -or $_.Message -match "publisher"
                        }

                        # Extract module names from the warnings
                        $modulesWithCertificateIssues = $certificateIssues | ForEach-Object {
                            # Attempt to extract module name from warning message, assuming a standard format
                            if ($_ -match "Module \'(.*?)\'") {
                                $matches[1]
                            }
                        }

                        Write-OutPut "Following modules could not be updated because of the certificate $($modulesWithCertificateIssues -as [string])"
                        Write-OutPut "certificateIssues $($certificateIssues -as [string])"
                    }
                }
                catch {
                    Write-Error "$($PSItem.Exception)"
                    continue
                }
            }
            else {
                Write-Verbose "$($_module.Name) are already up to date!"
            }

            # If switch -UninstallOldVersion has been used then the old versions will be uninstalled from the module
            if ($UninstallOldVersion -eq $true -and $_module.OldVersion.Count -gt 0) {
                Uninstall-rsModule -Module $_module.Name -OldVersion $_module.OldVersion
            }
            else {
                Write-Verbose "$($_module.Name) don't have any older versions to uninstall!"
            }
        }
    }
    #Install module if they want that 
    else {
        # If the switch InstallMissing are set to true the modules will get installed if they are missing
        if ($InstallMissing -eq $true) {
            try {
                Write-Output "$($_module.name) are not installed, installing $($_module.name)..."
                Install-Module -Name $_module.name -Scope $Scope -AllowPrerelease:$AllowPrerelease -AcceptLicense -Force
                Write-Output "$($_module.name) has now been installed!"
            }
            catch {
                Write-Error "$($PSItem.Exception)"
                continue
            }
        }
        else {
            Write-Verbose "$($_module.name) are not installed, you have not chosen to install missing modules"
        }
    }
    
    <#if ($ImportModule -eq $true) {
        # Collect all of the imported modules.
        Write-Verbose "Collecting all of the installed modules..."
        $ImportedModules = Get-Module | Select-Object Name, Version

        # Import module if it's not imported
        Write-Verbose "Starting to import the modules..."
        foreach ($_module in $Module) {
            if ($_module -in $ImportedModules.Name) {
                Write-Verbose "$($_module) are already imported!"
            }
            else {
                try {
                    Write-Output "Importing $($_module)..."
                    Import-Module -Name $_module -Force
                    Write-Output "$($_module) has been imported!"
                }
                catch {
                    Write-Error "$($PSItem.Exception)"
                    continue
                }
            }
        }
    }#>

    Write-Output "`n=== \\\ Script Finished! /// ===`n"
}