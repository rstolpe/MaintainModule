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
        [Parameter(Mandatory = $true, HelpMessage = 'Enter installed module objects for a single module name.')]
        [ValidateNotNullOrEmpty()]
        [psobject[]]$InstalledModule
    )

    $latestModule = $null
    $latestVersion = $null
    $oldVersions = [System.Collections.Generic.List[version]]::new()

    foreach ($moduleInfo in $InstalledModule) {
        try {
            [version]$parsedVersion = $moduleInfo.Version
        }
        catch {
            throw "Failed to parse the installed version for module '$($moduleInfo.Name)'. $($PSItem.Exception.Message)"
        }

        if ($null -eq $latestVersion -or $parsedVersion -gt $latestVersion) {
            if ($null -ne $latestVersion) {
                [void]$oldVersions.Add($latestVersion)
            }

            $latestVersion = $parsedVersion
            $latestModule = $moduleInfo
            continue
        }

        if ($parsedVersion -lt $latestVersion) {
            [void]$oldVersions.Add($parsedVersion)
        }
    }

    return [PSCustomObject]@{
        Name          = $latestModule.Name
        Repository    = $latestModule.Repository
        OldVersion    = $oldVersions.ToArray()
        LatestVersion = $latestVersion
    }
}

function Get-rsCallerPreferenceMap {
    [CmdletBinding()]
    param()

    $commonParameters = @{}

    # Forward caller preferences so nested commands honor -Verbose and -WhatIf consistently.
    if ($VerbosePreference -eq [System.Management.Automation.ActionPreference]::Continue) {
        $commonParameters.Verbose = $true
    }

    if ($WhatIfPreference) {
        $commonParameters.WhatIf = $true
    }

    return $commonParameters
}

function Get-rsRequestedModuleList {
    [CmdletBinding()]
    param(
        [Parameter(HelpMessage = 'Enter module names to normalize and de-duplicate.')]
        [AllowNull()]
        [AllowEmptyCollection()]
        [string[]]$Module
    )

    $requestedModules = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($moduleName in $Module) {
        if ([string]::IsNullOrWhiteSpace($moduleName)) {
            continue
        }

        [void]$requestedModules.Add($moduleName.Trim())
    }

    return @($requestedModules)
}

function Get-rsLatestRepositoryModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, HelpMessage = 'Enter the name of the module to look up in the repository.')]
        [ValidateNotNullOrEmpty()]
        [string]$ModuleName,
        [Parameter(Mandatory = $false, HelpMessage = 'Enter the repository to query when one is known.')]
        [AllowEmptyString()]
        [string]$Repository,
        [Parameter(Mandatory = $false, HelpMessage = 'Include prerelease versions when querying the repository.')]
        [switch]$AllowPrerelease
    )

    $findModuleParameters = @{
        Name        = $ModuleName
        ErrorAction = 'Stop'
    }

    if (-not [string]::IsNullOrWhiteSpace($Repository)) {
        $findModuleParameters.Repository = $Repository
    }

    if ($AllowPrerelease) {
        $findModuleParameters.AllowPrerelease = $true
    }

    # Find-Module returns the newest matching version by default, so an AllVersions query is unnecessary here.
    return Find-Module @findModuleParameters
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
        YouTube:        https://www.youtube.com/@rwidmark
        Linkedin:       https://www.linkedin.com/in/rwidmark/
        GitHub:         https://github.com/rwidmark
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Enter the module or modules you want to uninstall older version of, if not used all older versions will be uninstalled")]
        [Alias('Name')]
        [ValidateNotNullOrEmpty()]
        [string[]]$Module,
        [Parameter(Mandatory = $false, HelpMessage = 'Enter the module versions that should be removed.')]
        [ValidateNotNullOrEmpty()]
        [version[]]$OldVersion,
        [Parameter(Mandatory = $false, HelpMessage = 'Allow prerelease versions when uninstalling a specific version.')]
        [switch]$AllowPrerelease
    )

    begin {
        $versionsToRemove = @($OldVersion | Where-Object { $null -ne $_ })
        $moduleNames = Get-rsRequestedModuleList -Module $Module
    }

    process {
        foreach ($currentModule in $moduleNames) {
            Write-Output "START - Uninstall older versions of $currentModule"
            Write-Output "Please wait, this can take some time..."

            foreach ($_version in $versionsToRemove) {
                if ($PSCmdlet.ShouldProcess("$currentModule $($_version)", 'Uninstall module version')) {
                    Write-Verbose "Uninstalling version $($_version) of $($currentModule)..."
                    try {
                        $uninstallModuleParameters = @{
                            Name            = $currentModule
                            RequiredVersion = $_version
                            Force           = $true
                            ErrorAction     = 'Stop'
                        }

                        if ($AllowPrerelease) {
                            $uninstallModuleParameters.AllowPrerelease = $true
                        }

                        Uninstall-Module @uninstallModuleParameters
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
        [ValidateNotNullOrEmpty()]
        [string[]]$Module
    )

    begin {
        $returnCode = 0
        $returnData = [ordered]@{}
        $returnModule = [System.Collections.Generic.List[object]]::new()
        $missingModule = [System.Collections.Generic.List[string]]::new()
        $requestedModules = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    }

    process {
        foreach ($moduleName in $Module) {
            if ([string]::IsNullOrWhiteSpace($moduleName)) {
                continue
            }

            [void]$requestedModules.Add($moduleName.Trim())
        }
    }

    end {
        if ($requestedModules.Count -eq 0) {
            try {
                Write-Verbose 'Caching all installed modules from the system...'
                $allInstalledModules = @(Get-InstalledModule -AllVersions -ErrorAction Stop)
            }
            catch {
                throw "Failed to collect installed modules. $($PSItem.Exception.Message)"
            }

            $groupedModules = [System.Collections.Generic.Dictionary[string, System.Collections.Generic.List[object]]]::new([System.StringComparer]::OrdinalIgnoreCase)
            foreach ($installedModule in $allInstalledModules) {
                if (-not $groupedModules.ContainsKey($installedModule.Name)) {
                    $groupedModules[$installedModule.Name] = [System.Collections.Generic.List[object]]::new()
                }

                [void]$groupedModules[$installedModule.Name].Add($installedModule)
            }

            foreach ($moduleName in ($groupedModules.Keys | Sort-Object)) {
                $moduleInfo = Get-rsModuleDetail -InstalledModule $groupedModules[$moduleName].ToArray()
                [void]$returnModule.Add($moduleInfo)
            }
        }
        else {
            Write-Verbose 'Looking if the modules exist in the system...'
        foreach ($moduleName in $requestedModules) {
            try {
                $installedModuleVersions = @(Get-InstalledModule -Name $moduleName -AllVersions -ErrorAction Stop)
                }
                catch {
                    Write-Warning "$($moduleName) is not installed, skipping this module..."
                    [void]$missingModule.Add($moduleName)
                    continue
                }

                $moduleInfo = Get-rsModuleDetail -InstalledModule $installedModuleVersions
                if ($null -ne $moduleInfo) {
                    Write-Verbose "$($moduleName) is installed, collecting information about it..."
                    [void]$returnModule.Add($moduleInfo)
                }
                else {
                    Write-Warning "$($moduleName) is not installed, skipping this module..."
                    [void]$missingModule.Add($moduleName)
                }
            }
        }

        if ($returnModule.Count -eq 0) {
            $returnCode = 1
            if ($requestedModules.Count -gt 0) {
                Write-Warning 'No matching installed modules were found for the requested module names...'
            }
            else {
                Write-Warning 'No installed modules were found...'
            }
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
        Write-Verbose 'Checking if PowerShell Gallery is set to trusted...'

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
        YouTube:        https://www.youtube.com/@rwidmark
        Linkedin:       https://www.linkedin.com/in/rwidmark/
        GitHub:         https://github.com/rwidmark
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Enter module or modules that you want to update, if you don't enter any, all of the modules will be updated")]
        [Alias('Name')]
        [ValidateNotNullOrEmpty()]
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
        [Parameter(Mandatory = $false, HelpMessage = 'Include prerelease versions when searching, installing, and updating modules.')]
        [switch]$AllowPrerelease
    )

    begin {
        $commonParameters = Get-rsCallerPreferenceMap
        $requestedModules = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

        Write-Output "`n=== Module Maintenance - Widmark.dev 2025 ==="
        Write-Output "Please wait, this can take some time...`n"

        Test-rsComponent @commonParameters

        Write-Output "START - Updating modules`n"
    }

    process {
        foreach ($moduleName in $Module) {
            if ([string]::IsNullOrWhiteSpace($moduleName)) {
                continue
            }

            [void]$requestedModules.Add($moduleName.Trim())
        }
    }

    end {
        $modulesToProcess = @($requestedModules)
        $getModuleInfo = if ($modulesToProcess.Count -gt 0) {
            Get-rsInstalledModule -Module $modulesToProcess
        }
        else {
            Get-rsInstalledModule
        }

        if ($getModuleInfo.ReturnCode -eq 0) {
            foreach ($_module in @($getModuleInfo.Module)) {
                Write-Verbose "Collecting all installed version of $($_module.Name)..."

                try {
                    Write-Verbose "Looking up the latest version of $($_module.Name)..."
                    $latestRepositoryModule = Get-rsLatestRepositoryModule -ModuleName $_module.Name -Repository $_module.Repository -AllowPrerelease:$AllowPrerelease
                    if ($null -eq $latestRepositoryModule) {
                        Write-Warning "No repository versions were found for $($_module.Name), skipping this module..."
                        continue
                    }

                    [version]$collectLatestVersion = $latestRepositoryModule.Version
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
                                AcceptLicense     = $true
                                Force             = $true
                                ErrorAction       = 'Stop'
                            }

                            if ($AllowPrerelease) {
                                $updateModuleParameters.AllowPrerelease = $true
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
                    Write-Verbose "$($_module.Name) is already up to date!"
                }

                if ($UninstallOldVersion) {
                    $versionsToRemove = @($versionsToRemove | Select-Object -Unique)
                    if ($versionsToRemove.Count -gt 0) {
                        Uninstall-rsModule -Module $_module.Name -OldVersion $versionsToRemove -AllowPrerelease:$AllowPrerelease @commonParameters
                    }
                    else {
                        Write-Verbose "$($_module.Name) don't have any older versions to uninstall!"
                    }
                }
            }
        }

        if ($InstallMissing -and @($getModuleInfo.MissingModule).Count -gt 0) {
            foreach ($missingModule in @($getModuleInfo.MissingModule)) {
                Write-Output "$missingModule is not installed, installing $missingModule..."

                if ($PSCmdlet.ShouldProcess($missingModule, 'Install missing module')) {
                    try {
                        $installModuleParameters = @{
                            Name            = $missingModule
                            Scope           = $Scope
                            AcceptLicense   = $true
                            Force           = $true
                            ErrorAction     = 'Stop'
                        }

                        if ($AllowPrerelease) {
                            $installModuleParameters.AllowPrerelease = $true
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
        Write-Output "`n=== \\\ Script Finished! /// ===`n"
    }
}
