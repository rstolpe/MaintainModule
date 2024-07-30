[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$CheckIfTrusted = Get-PSRepository -name PSGallery | Select-Object InstallationPolicy -ExpandProperty InstallationPolicy
if ($CheckIfTrusted -eq "Untrusted") {
    try {
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    }
    catch {
        Write-Error "$($PSItem.Exception)"
        continue
    }
}

$ModulePath = "$PSScriptRoot\MaintainModule"
Publish-Module -Path $ModulePath -NuGetApiKey $Env:PSGALLERY