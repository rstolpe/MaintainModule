#param (
#    [string] $version,
#    [string] $preReleaseTag,
#    [string] $apiKey
#)

$Version = "0.0.7"
$preReleaseTag = "-beta"
#$apiKey = "test"

# Creating ArrayList for use later in the script
[System.Collections.ArrayList]$FunctionPSD = @()

# Name of the module
$ModuleName = $(Get-Location) -split "/" | select -last 1
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$ModuleFolderPath = "$($scriptPath)/$($ModuleName)"
$srcPath = "$($scriptPath)/src"
$srcFunctionPath = "$($scriptPath)/src/Function"
$outPSMFile = "$($ModuleFolderPath)/$($ModuleName).psm1"
$outPSDFile = "$($ModuleFolderPath)/$($ModuleName).psd1"
$psdTemplate = "$($srcPath)/$($ModuleName).psd1.source"

Write-OutPut "== Preparing $($ModuleName) for publishing ==`n"
Write-OutPut "Starting to build the module, please wait..."

if (!(Test-Path $ModuleFolderPath)) {
    Write-Verbose "Creating folder $($ModuleFolderPath)"
    New-Item -Path $ModuleFolderPath -ItemType Directory -Force
}
else {
    if (Test-Path $outPSMFile) {
        Write-Verbose "Removing file $($outPSMFile)"
        Remove-Item -Path $outPSMFile -Force
    }

    if (Test-Path $outPSDFile) {
        Write-Verbose "Removing file $($outPSDFile)"
        Remove-Item -Path $outPSDFile -Force
    }
}

# Collecting all .ps1 files that are located in src/function folders
Write-Verbose "Collecting all .ps1 files from $($srcFunctionPath)"
$MigrateFunction = @( Get-ChildItem -Path $srcFunctionPath/*.ps1 -ErrorAction SilentlyContinue -Recurse )

# Looping trough the .ps1 files and migrating them to one singel .psm1 file and saving it in the module folder
Write-Verbose "Start to migrate all functions in to the .psm1 file and collecting the function names to add in the FunctionToExport in the .psd1 file"
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

# I know that I need to fix this one, but it's the best I can think of for now to remove the last , in the ArrayList
$FunctionPSD = $FunctionPSD | ForEach-Object { 
    if ( $FunctionPSD.IndexOf($_) -eq ($FunctionPSD.count - 1) ) {
        $_.replace(",", "")
    }
    else { $_ }  
}

# Copy the .psd1.source file from the srcPath to the module folder and removing the .source ending
Write-Verbose "Copy the file $($psdTemplate) to $($outPSDFile)"
Copy-Item -Path $psdTemplate -Destination $outPSDFile -Force

# Getting the content from the .psd1 file
Write-Verbose "Getting the content from file $($outPSDFile)"
$fileContent = Get-Content -Path $outPSDFile

# Changing version, preReleaseTag and function in the .psd1 file
$fileContent = $fileContent -replace '{{version}}', $version
$fileContent = $fileContent -replace '{{preReleaseTag}}', $preReleaseTag
$fileContent = $fileContent -replace '{{function}}', $FunctionPSD

Write-Verbose "Changing the placeholders in $($outPSDFile)"
Set-Content -Path $outPSDFile -Value $fileContent -Force

Write-Output "---/// $($ModuleName) is now prepared for publishing! ///---"

#Publish-Module `
#    -Path $scriptPath\$ModuleName `
#    -NuGetApiKey $apiKey `
#    -Verbose -Force