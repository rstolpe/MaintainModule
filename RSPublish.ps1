param (
    # Set this to true before releasing the module
    [Parameter(Mandatory = $false, HelpMessage = "Enter the version number of this release")]
    [string]$Version = "0.0.8",
    # Fix this
    [Parameter(Mandatory = $false, HelpMessage = ".")]
    [string]$preRelease,
    [Parameter(Mandatory = $false, HelpMessage = "Use this switch to publish this module on PSGallery")]
    [bool]$Publish = $false,
    # Validate so if $Publish is true this is needed
    [Parameter(Mandatory = $false, HelpMessage = "Enter API key for PSGallery")]
    [string]$apiKey
)


$preReleaseTag = "beta"

# Creating ArrayList for use later in the script
[System.Collections.ArrayList]$FunctionPSD = @()

$Year = (Get-Date).Year
$ManifestDate = Get-Date -Format "yyyy-MM-dd"

# Gets the folder name from the folder where this script are located
$ModuleName = $(Get-Location) -split "/" | Select-Object -last 1

# Paths for different sections inside the module
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$ModuleFolderPath = "$($scriptPath)/$($ModuleName)"
$srcPath = "$($scriptPath)/.src"
$srcPublicFunctionPath = "$($scriptPath)/.src/public/function"
$outPSMFile = "$($ModuleFolderPath)/$($ModuleName).psm1"
$outPSDFile = "$($ModuleFolderPath)/$($ModuleName).psd1"
$psdTemplate = "$($srcPath)/$($ModuleName).psd1.source"
$psmLicensPath = "$($srcPath)/License"
$EMBSourceFiles = "$($env:PSModulePath)/EasyModuleBuild/source_files"

# Needed folders
$srcNeededFolders = @("$($srcPath)/Private", "$($srcPath)/Private/Function", "$($srcPath)/Public", "$($srcPath)/Public/Function")

# Needed files
$moduleNeededFiles = @("$($scriptPath)/.gitignore", "$($scriptPath)/LICENSE", "$($scriptPath)/README.md")

Write-OutPut "`n== Preparing $($ModuleName) for publishing ==`n"
Write-OutPut "Starting to build the module, please wait..."

if (!(Test-Path $ModuleFolderPath)) {
    Write-Verbose "Creating folder $($ModuleFolderPath)"
    [void](New-Item -Path $ModuleFolderPath -ItemType Directory -Force)
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

if (!(Test-Path $srcPath)) {
    Write-Verbose "Creating folder $($srcPath)"
    New-Item -Path $srcPath -ItemType Directory -Force
    foreach ($f in $srcNeededFolders) {
        Write-Verbose "Creating folder $($f)"
        [void](New-Item -Path $f -ItemType Directory -Force)
    }
}
else {
    foreach ($f in $srcNeededFolders) {
        if (!(Test-Path $f)) {
            Write-Verbose "Creating folder $($f)"
            [void](New-Item -Path $f -ItemType Directory -Force)
        }
    }
}

# Adding the text from the gnu3_add_file_licens.source to the to of the .psm1 file for licensing of GNU v3
$psmLicens = Get-Content -Path "$($psmLicensPath)/gnu3_add_file_licens.source" -ErrorAction SilentlyContinue
$psmLicens | Add-Content -Path $outPSMFile

# Collecting all .ps1 files that are located in src/function folders
Write-Verbose "Collecting all .ps1 files from $($srcPublicFunctionPath)"
$MigrateFunction = @( Get-ChildItem -Path $srcPublicFunctionPath/*.ps1 -ErrorAction SilentlyContinue -Recurse )

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
    [void]($FunctionPSD.Add($function))
}

# if $MigrateFunction are not empty remove the last , from the $FunctionPSD ArrayList
if ($null -ne $MigrateFunction) {
    # I know that I need to fix this one, but it's the best I can think of for now to remove the last , in the ArrayList
    $FunctionPSD = $FunctionPSD | ForEach-Object { 
        if ( $FunctionPSD.IndexOf($_) -eq ($FunctionPSD.count - 1) ) {
            $_.replace(",", "")
        }
        else { $_ }  
    }
}

# Change the placeholder in the $outPSMFile file
Write-Verbose "Getting the content from file $($outPSMFile)"
$PSMfileContent = Get-Content -Path $outPSMFile
Write-Verbose "Replacing the placeholders in the $($outPSMFile) file"
$PSMfileContent = $PSMfileContent -replace '{{year}}', $year

Write-Verbose "Setting the placeholders for $($outPSMFile)"
Set-Content -Path $outPSMFile -Value $PSMfileContent  -Force

# Copy the .psd1.source file from the srcPath to the module folder and removing the .source ending
Write-Verbose "Copy the file $($psdTemplate) to $($outPSDFile)"
Copy-Item -Path $psdTemplate -Destination $outPSDFile -Force

# Getting the content from the .psd1 file
Write-Verbose "Getting the content from file $($outPSDFile)"
$PSDfileContent = Get-Content -Path $outPSDFile

Write-Verbose "Replacing the placeholders in the $($outPSDFile) file"
$PSDfileContent = $PSDfileContent -replace '{{manifestDate}}', $ManifestDate
$PSDfileContent = $PSDfileContent -replace '{{moduleName}}', $ModuleName
$PSDfileContent = $PSDfileContent -replace '{{year}}', $Year
$PSDfileContent = $PSDfileContent -replace '{{version}}', $version
$PSDfileContent = $PSDfileContent -replace '{{preReleaseTag}}', $preReleaseTag

# If $FunctionPSD are empty, then adding @() instead according to best practices for performance
if ($null -ne $FunctionPSD) {
    $PSDfileContent = $PSDfileContent -replace '{{function}}', $FunctionPSD
}
else {
    $PSDfileContent = $PSDfileContent -replace '{{function}}', '@()'
}

Write-Verbose "Setting the placeholders for $($outPSDFile)"
Set-Content -Path $outPSDFile -Value $PSDfileContent -Force

if ($Publish -eq $true) {
    # Check so that the module has .ps1 and .psd1 files in the module folder before it trys to publish it.
    Write-Verbose "Publishing $($ModuleName) version $($version) to PowerShell Gallery"
    Publish-Module -Path $ModuleFolderPath -NuGetApiKey $apiKey -Force
    Write-Output "---/// $($ModuleName) version $($Version) has now been built and published to PowerShell Gallery! ///---"
}
else {
    Write-Output "---/// $($ModuleName) version $($Version)  is now prepared for publishing! ///---"
}