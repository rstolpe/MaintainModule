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
        Uninstall-RSModule -Module "VMWare.PowerCLI", "ImportExcel"
        # This will uninstall all older versions of VMWare.PowerCLI and ImportExcel from the system.

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
        [Parameter(Mandatory = $false, HelpMessage = "Enter the module or modules (separated with ,) you want to uninstall")]
        [string[]]$Module
    )

    Write-Output "`n=== Starting to uninstall older versions of modules ===`n"
    Write-Output "Please wait, this can take some time..."

    Write-Verbose "Caching all installed modules from the system..."
    $InstalledModules = Get-InstalledModule | Select-Object Name, Version | Sort-Object Name

    # If Module parameter is empty populate it with all modules that are installed on the system
    if ([string]::IsNullOrEmpty($Module)) {
        Write-Verbose "Parameter Module are empty populate it with all installed modules from the system..."
        $Module = $InstalledModules.Name
    }
    else {
        Write-Verbose "User has added modules to the Module parameter, splitting them"
        $OldModule = $Module.Split(",").Trim()
        [System.Collections.ArrayList]$Module = @()

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

    foreach ($m in $Module) {
        Write-Verbose "Collecting all installed version of the module $($m)"
        $GetAllInstalledVersions = Get-InstalledModule -Name $m -AllVersions | Sort-Object { $_.Version -as [version] } -Descending | Select-Object -ExpandProperty Version

        # If the module has more then one version loop trough the versions and only keep the most current one
        if ($GetAllInstalledVersions.Count -gt 1) {
            $MostRecentVersion = $null
            [version]$MostRecentVersion = $GetAllInstalledVersions[0]
            Foreach ($Version in $GetAllInstalledVersions | Where-Object { [version]$_ -lt [version]$MostRecentVersion }) {
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
            # bygga in en check så att den verkligen kan verifiera detta
            Write-Output "All older versions of $($m) are now uninstalled, the only installed version of $($m) is $($MostRecentVersion)"
        }
        else {
            Write-Verbose "$($m) don't have any older versions installed then $($GetAllInstalledVersions), no need to uninstall anything."
        }
    }
    Write-Output "`n---/// Script Finished! ///---"
}