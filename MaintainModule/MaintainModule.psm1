<#
    MIT License

    Copyright (C) 2025 Robin Widmark.

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
function Get-rsModuleDetail {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [psobject[]]$InstalledModule
    )

    $sortedModuleVersions = @($InstalledModule | Sort-Object { $_.Version -as [version] } -Descending)
    if ($sortedModuleVersions.Count -eq 0) {
        return $null
    }

    [version]$latestVersion = $sortedModuleVersions[0].Version
    $oldVersions = @($sortedModuleVersions | Where-Object { $_.Version -ne $latestVersion } | ForEach-Object { [version]$_.Version })

    return [PSCustomObject]@{
        Name          = $sortedModuleVersions[0].Name
        Repository    = $sortedModuleVersions[0].Repository
        OldVersion    = $oldVersions
        LatestVersion = $latestVersion
    }
}

function Uninstall-rsModule {
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
        https://github.com/rwidmark/MaintainModule/blob/main/README.md

        .NOTES
        Author:         Robin Widmark
        Mail:           robin@widmark.dev
        Website/Blog:   https://widmark.dev
        X:              https://x.com/widmark_robin
        Mastodon:       https://mastodon.social/@rwidmark
YouTube:https://www.youtube.com/@rwidmark
        Linkedin:       https://www.linkedin.com/in/rwidmark/
        GitHub:         https://github.com/rwidmark
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Enter the module or modules you want to uninstall older version of, if not used all older versions will be uninstalled")]
        [Alias('Name')]
        [string[]]$Module,
        [Parameter(Mandatory = $false, HelpMessage = ".")]
        [version[]]$OldVersion,
        [Parameter(Mandatory = $false, HelpMessage = "If this is used updates etc. be for prerelease")]
        [bool]$AllowPrerelease = $false
    )

    begin {
        $versionsToRemove = @($OldVersion | Where-Object { $null -ne $_ })
    }

    process {
        foreach ($currentModule in @($Module)) {
            if ([string]::IsNullOrWhiteSpace($currentModule)) {
                continue
            }

            Write-Output "START - Uninstall older versions of $currentModule"
            Write-Output "Please wait, this can take some time..."

            foreach ($_version in $versionsToRemove) {
                if ($PSCmdlet.ShouldProcess("$currentModule $($_version)", 'Uninstall module version')) {
                    Write-Verbose "Uninstalling version $($_version) of $($currentModule)..."
                    try {
                        Uninstall-Module -Name $currentModule -RequiredVersion $_version -AllowPrerelease:$AllowPrerelease -Force -ErrorAction Stop
                    }
                    catch {
                        Write-Error "Failed to uninstall version $($_version) of $($currentModule). $($PSItem.Exception.Message)"
                        continue
                    }
                }
            }

            Write-Output "FINISHED - All older versions of $currentModule are now uninstalled!"
        }
    }

    end {
        if ($versionsToRemove.Count -eq 0) {
            Write-Verbose 'No module versions were supplied for uninstall.'
        }
    }
}

function Get-rsInstalledModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Enter module or modules that you want to update, if you don't enter any, all of the modules will be updated")]
        [Alias('Name')]
        [string[]]$Module
    )

    begin {
        $returnCode = 0
        $returnData = [ordered]@{}
        $returnModule = [System.Collections.Generic.List[object]]::new()
        $missingModule = [System.Collections.Generic.List[string]]::new()
        $requestedModules = [System.Collections.Generic.List[string]]::new()
        $installedModuleMap = @{}

        try {
            Write-Verbose 'Caching all installed modules from the system...'
            $allInstalledModules = @(Get-InstalledModule -AllVersions -ErrorAction Stop)
        }
        catch {
            throw "Failed to collect installed modules. $($PSItem.Exception.Message)"
        }

        foreach ($moduleGroup in ($allInstalledModules | Group-Object Name)) {
            $moduleInfo = Get-rsModuleDetail -InstalledModule $moduleGroup.Group
            if ($null -ne $moduleInfo) {
                $installedModuleMap[$moduleGroup.Name] = $moduleInfo
            }
        }
    }

    process {
        foreach ($moduleName in @($Module)) {
            if ([string]::IsNullOrWhiteSpace($moduleName)) {
                continue
            }

            if ($moduleName -notin $requestedModules) {
                [void]$requestedModules.Add($moduleName)
            }
        }
    }

    end {
        if ($requestedModules.Count -eq 0) {
            foreach ($moduleInfo in ($installedModuleMap.Values | Sort-Object Name)) {
                [void]$returnModule.Add($moduleInfo)
            }
        }
        else {
            Write-Verbose 'Looking so the modules exists in the system...'
            foreach ($moduleName in $requestedModules) {
                if ($installedModuleMap.ContainsKey($moduleName)) {
                    Write-Verbose "$($moduleName) is installed, collecting information about it..."
                    [void]$returnModule.Add($installedModuleMap[$moduleName])
                }
                else {
                    Write-Warning "$($moduleName) is not installed, skipping this module..."
                    [void]$missingModule.Add($moduleName)
                }
            }
        }

        if ($returnModule.Count -eq 0) {
            $returnCode = 1
            Write-Warning 'No modules was found...'
        }

        $moduleResult = if ($returnModule.Count -gt 0) { $returnModule.ToArray() } else { $null }
        $missingResult = if ($missingModule.Count -gt 0) { $missingModule.ToArray() } else { @() }

        $returnData.Add('ReturnCode', $returnCode)
        $returnData.Add('Module', $moduleResult)
        $returnData.Add('MissingModule', $missingResult)

        return $returnData
    }
}

function Test-rsComponent {
    [CmdletBinding(SupportsShouldProcess)]
    param(

    )

    begin {
        Write-Verbose 'Making sure that TLS 1.2 is used...'
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    }

    process {
        Write-Verbose 'Checking if PowerShell Gallery are set to trusted...'

        try {
            $psGallery = Get-PSRepository -Name PSGallery -ErrorAction Stop
        }
        catch {
            throw "Failed to read PSGallery configuration. $($PSItem.Exception.Message)"
        }

        if ($psGallery.InstallationPolicy -eq 'Untrusted') {
            if ($PSCmdlet.ShouldProcess('PSGallery', 'Set installation policy to Trusted')) {
                try {
                    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction Stop
                    Write-Output "PowerShell Gallery was not set as trusted, it's now set as trusted!"
                }
                catch {
                    throw "Failed to set PSGallery as trusted. $($PSItem.Exception.Message)"
                }
            }
        }
        else {
            Write-Verbose "PowerShell Gallery was already set to trusted, continuing!"
        }
    }

    end {
    }
}

function Update-rsModule {
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

        .PARAMETER UninstallOldVersion
        If this switch are used all of the old versions of your modules will get uninstalled and only the current version will be installed

        .PARAMETER InstallMissing
        If you use this switch and the modules that are specified in the Module parameter are not installed on the system they will be installed.

        .PARAMETER AllowPrerelease
        If you set this to $true Pre-Releases are going to be installed / updated

        .PARAMETER SkipPublisherCheck
        If you set this to $true PublisherCheck will be ignored, this is something that for example are needed for Pester and PowerCLI because there certificate are not valid for some reason.

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
        https://github.com/rwidmark/MaintainModule/blob/main/README.md

        .NOTES
        Author:         Robin Widmark
        Mail:           robin@widmark.dev
        Website/Blog:   https://widmark.dev
        X:              https://x.com/widmark_robin
        Mastodon:       https://mastodon.social/@rwidmark
YouTube:https://www.youtube.com/@rwidmark
        Linkedin:       https://www.linkedin.com/in/rwidmark/
        GitHub:         https://github.com/rwidmark
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Enter module or modules that you want to update, if you don't enter any, all of the modules will be updated")]
        [Alias('Name')]
        [string[]]$Module,
        [Parameter(Mandatory = $false, HelpMessage = "Enter CurrentUser or AllUsers depending on what scope you want to change your modules, default is CurrentUser")]
        [ValidateSet('CurrentUser', 'AllUsers')]
        [string]$Scope = 'CurrentUser',
        [Parameter(Mandatory = $false, HelpMessage = 'Uninstalls all old versions of the modules')]
        [switch]$UninstallOldVersion = $false,
        [Parameter(Mandatory = $false, HelpMessage = 'Install all of the modules that has been entered in module that are not installed on the system')]
        [switch]$InstallMissing = $false,
        [Parameter(Mandatory = $false, HelpMessage = "Don't check publishers certificate")]
        [switch]$SkipPublisherCheck = $false,
        [Parameter(Mandatory = $false, HelpMessage = 'If this is used updates etc. be for prerelease')]
        [bool]$AllowPrerelease = $false
    )

    begin {
        $requestedModules = [System.Collections.Generic.List[string]]::new()

        Write-Output "`n=== Module Maintenance - Widmark.dev 2025 ==="
        Write-Output "Please wait, this can take some time...`n"

        Test-rsComponent

        Write-Output "START - Updating modules`n"
    }

    process {
        foreach ($moduleName in @($Module)) {
            if ([string]::IsNullOrWhiteSpace($moduleName)) {
                continue
            }

            if ($moduleName -notin $requestedModules) {
                [void]$requestedModules.Add($moduleName)
            }
        }
    }

    end {
        $targetModules = if ($requestedModules.Count -gt 0) { $requestedModules.ToArray() } else { $null }
        $getModuleInfo = Get-rsInstalledModule -Module $targetModules

        if ($getModuleInfo.ReturnCode -eq 0) {
            foreach ($_module in @($getModuleInfo.Module)) {
                Write-Verbose "Collecting all installed version of $($_module.Name)..."

                try {
                    Write-Verbose "Looking up the latest version of $($_module.Name)..."
                    $findModuleParameters = @{
                        Name        = $_module.Name
                        AllVersions = $true
                        ErrorAction = 'Stop'
                    }

                    if (-not [string]::IsNullOrWhiteSpace($_module.Repository)) {
                        $findModuleParameters.Repository = $_module.Repository
                    }

                    $availableVersions = @(Find-Module @findModuleParameters | Sort-Object { $_.Version -as [version] } -Descending)
                    if ($availableVersions.Count -eq 0) {
                        Write-Warning "No repository versions were found for $($_module.Name), skipping this module..."
                        continue
                    }

                    [version]$collectLatestVersion = $availableVersions[0].Version
                }
                catch {
                    Write-Error "Failed to look up the latest version of $($_module.Name). $($PSItem.Exception.Message)"
                    continue
                }

                $versionsToRemove = @($_module.OldVersion)
                $requiresUpdate = $_module.LatestVersion -lt $collectLatestVersion

                if ($requiresUpdate) {
                    Write-Output "Found a newer version of $($_module.Name), version $collectLatestVersion"
                    Write-Output "Updating $($_module.Name) from $($_module.LatestVersion) to version $collectLatestVersion..."

                    if ($PSCmdlet.ShouldProcess($_module.Name, "Update module to version $collectLatestVersion")) {
                        try {
                            $updateModuleParameters = @{
                                Name              = $_module.Name
                                Scope             = $Scope
                                AllowPrerelease   = $AllowPrerelease
                                AcceptLicense     = $true
                                Force             = $true
                                ErrorAction       = 'Stop'
                            }

                            if ($SkipPublisherCheck) {
                                $updateModuleParameters.SkipPublisherCheck = $true
                            }

                            Update-Module @updateModuleParameters
                            Write-Output "$($_module.Name) has now been updated to version $collectLatestVersion!"
                            $versionsToRemove += $_module.LatestVersion
                        }
                        catch {
                            Write-Error "Failed to update $($_module.Name). $($PSItem.Exception.Message)"
                            continue
                        }
                    }
                }
                else {
                    Write-Verbose "$($_module.Name) are already up to date!"
                }

                if ($UninstallOldVersion) {
                    $versionsToRemove = @($versionsToRemove | Sort-Object -Unique)
                    if ($versionsToRemove.Count -gt 0) {
                        Uninstall-rsModule -Module $_module.Name -OldVersion $versionsToRemove -AllowPrerelease:$AllowPrerelease
                    }
                    else {
                        Write-Verbose "$($_module.Name) don't have any older versions to uninstall!"
                    }
                }
            }
        }

        if ($InstallMissing -and @($getModuleInfo.MissingModule).Count -gt 0) {
            foreach ($missingModule in @($getModuleInfo.MissingModule)) {
                Write-Output "$missingModule are not installed, installing $missingModule..."

                if ($PSCmdlet.ShouldProcess($missingModule, 'Install missing module')) {
                    try {
                        $installModuleParameters = @{
                            Name            = $missingModule
                            Scope           = $Scope
                            AllowPrerelease = $AllowPrerelease
                            AcceptLicense   = $true
                            Force           = $true
                            ErrorAction     = 'Stop'
                        }

                        if ($SkipPublisherCheck) {
                            $installModuleParameters.SkipPublisherCheck = $true
                        }

                        Install-Module @installModuleParameters
                        Write-Output "$missingModule has now been installed!"
                    }
                    catch {
                        Write-Error "Failed to install $missingModule. $($PSItem.Exception.Message)"
                        continue
                    }
                }
            }
        }
        elseif (-not $InstallMissing -and @($getModuleInfo.MissingModule).Count -gt 0) {
            foreach ($missingModule in @($getModuleInfo.MissingModule)) {
                Write-Verbose "$missingModule are not installed, you have not chosen to install missing modules"
            }
        }

        Write-Output "`n=== \\\ Script Finished! /// ===`n"
    }
}
