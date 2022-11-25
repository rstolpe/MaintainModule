#param (
#    [string] $version,
#    [string] $preReleaseTag,
#    [string] $apiKey
#)
$Version = "1.0"
$preReleaseTag = "-beta"
#$apiKey = "test"

# Creating ArrayList for use later in the script
[System.Collections.ArrayList]$FunctionPSD = @()

# Name of the module
$ModuleName = "MaintainModule"
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$ModuleFolderPath = "$($scriptPath)/$($ModuleName)"
$srcPath = "$($scriptPath)/src"
$srcFunctionPath = "$($scriptPath)/src/Function"
$outPSMFile = "$($ModuleFolderPath)/$($ModuleName).psm1"
$outPSDFile = "$($ModuleFolderPath)/$($ModuleName).psd1"
$psdTemplate = "$($srcPath)/$($ModuleName).psd1.source"

Write-Output "Starting to build the module, please wait..."

if (!(Test-Path $ModuleFolderPath)) {
    New-Item -Path $ModuleFolderPath -ItemType Directory -Force
}
else {
    if (Test-Path $outPSMFile) {
        Remove-Item -Path $outPSMFile -Force
    }

    if (Test-Path $outPSDFile) {
        Remove-Item -Path $outPSDFile -Force
    }
}

# Collecting all .ps1 files that are located in src/function folders
$MigrateFunction = @( Get-ChildItem -Path $srcFunctionPath/*.ps1 -ErrorAction SilentlyContinue -Recurse )

# Looping trough the .ps1 files and migrating them to one singel .psm1 file and saving it in the module folder
foreach ($function in $MigrateFunction) {
    # Migrates all of the .ps1 files that are located in src/Function in to one .psm1 file saved in the module folder
    $Results = [System.Management.Automation.Language.Parser]::ParseFile($function, [ref]$null, [ref]$null)
    $Functions = $Results.EndBlock.Extent.Text
    $Functions | Add-Content -Path $outPSMFile

    # Converting the function name to fit the .psd1 file for exporting
    $function = $function.Name -replace ".ps1"
    $function = """$($function)"","
    $function.trim()

    # Collect the name of all .ps1 files so it can be added as functions in the psd1 file.
    $FunctionPSD.Add($function)
}

# Copy the .psd1.source file from the srcPath to the module folder and removing the .source ending
Copy-Item -Path $psdTemplate -Destination $outPSDFile -Force

# Getting the content from the .psd1 file
$fileContent = Get-Content -Path $outPSDFile

# Changing version, preReleaseTag and function in the .psd1 file
$fileContent = $fileContent -replace '{{version}}', $version
$fileContent = $fileContent -replace '{{preReleaseTag}}', $preReleaseTag
$fileContent = $fileContent -replace '{{function}}', $FunctionPSD
Set-Content -Path $outPSDFile -Value $fileContent -Force

#Publish-Module `
#    -Path $scriptPath\$ModuleName `
#    -NuGetApiKey $apiKey `
#    -Verbose -Force