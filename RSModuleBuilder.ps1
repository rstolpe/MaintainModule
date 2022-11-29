param (
    [Parameter(Mandatory = $false, HelpMessage = "Enter the version number of this release")]
    [string]$Version = "1.0.0",
    [Parameter(Mandatory = $false, HelpMessage = ".")]
    [string]$preRelease = "Alpha",
    [Parameter(Mandatory = $false, HelpMessage = "Use this switch to publish this module on PSGallery")]
    [bool]$Publish = $false,
    [Parameter(Mandatory = $false, HelpMessage = "Enter API key for PSGallery")]
    [string]$apiKey
)

# THIS IS A BETA FILE DONT USE THIS FILE! ILL RELEASE A ALPHA VERSION OF THIS LATER ON!

#Requires -Modules PSScriptAnalyzer

# Creating ArrayList for use later in the script
[System.Collections.ArrayList]$FunctionPSD = @()

$Year = (Get-Date).Year
$TodaysDate = Get-Date -Format "yyyy-MM-dd"
$ModuleName = $(Get-Location) -split "/" | Select-Object -last 1
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$HelpPath = Join-Path -Path $scriptPath -ChildPath "help"
$ModuleFolderPath = Join-Path -Path $scriptPath -ChildPath $ModuleName
$srcPath = Join-Path -Path $scriptPath -ChildPath ".src"
$srcPublicFunctionPath = Join-Path -Path $srcPath -ChildPath "public/function"
$outPSMFile = Join-Path -Path $ModuleFolderPath -ChildPath "$($ModuleName).psm1"
$outPSDFile = Join-Path -Path $ModuleFolderPath -ChildPath "$($ModuleName).psd1"
$psdTemplate = Join-Path -Path $srcPath -ChildPath "$($ModuleName).psd1.source"
$psmLicensPath = Join-Path -Path $srcPath -ChildPath "License"
$TestPath = Join-Path -Path $scriptPath -ChildPath "test"

Write-OutPut "`n== Building module $($ModuleName) ==`n"
Write-OutPut "Starting to build the module, please wait..."

# Check so all the needed folders exists, if they don't they will get created.
Checkpoint-RSFolderFile -ModulePath $scriptPath -ModuleName $ModuleName -New $false

# Deleting existing files that will get replaced by this script
Remove-RSContent -ModuleName $ModuleName -ScriptPath $scriptPath -ExistingModule

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
    [void]($function.trim())

    # Collect the name of all .ps1 files so it can be added as functions in the psd1 file.
    [void]($FunctionPSD.Add($function))
}

# if $MigrateFunction are not empty remove the last , from the $FunctionPSD ArrayList
if ($null -ne $MigrateFunction) {
    $FunctionPSD = $FunctionPSD | ForEach-Object {
        if ( $FunctionPSD.IndexOf($_) -eq ($FunctionPSD.count - 1) ) {
            $_.replace(",", "")
        }
        else {
            $_
        }
    }
}

# Change the placeholder in the $outPSMFile file
Write-Verbose "Getting the content from file $($outPSMFile)"
$PSMfileContent = Get-Content -Path $outPSMFile

Write-Verbose "Replacing the placeholders in the $($outPSMFile) file"
$PSMfileContent = $PSMfileContent -replace '{{year}}', $year

Write-Verbose "Setting the placeholders for $($outPSMFile)"
Set-Content -Path $outPSMFile -Value $PSMfileContent -Force

# Copy the .psd1.source file from the srcPath to the module folder and removing the .source ending
Write-Verbose "Copy the file $($psdTemplate) to $($outPSDFile)"
Copy-Item -Path $psdTemplate -Destination $outPSDFile -Force

# Getting the content from the .psd1 file
Write-Verbose "Getting the content from file $($outPSDFile)"
$PSDfileContent = Get-Content -Path $outPSDFile

Write-Verbose "Replacing the placeholders in the $($outPSDFile) file"
$PSDfileContent = $PSDfileContent -replace '{{manifestDate}}', $TodaysDate
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

Write-Output "Running PSScriptAnalyzer on the .psd1 $($outPSDFile)..."
# If no issue are found that should be written in the outfile
$PSAnalyzerPSD = Invoke-ScriptAnalyzer -Path $outPSDFile -ReportSummary | select-object * | Out-File -Encoding UTF8BOM -FilePath $(Join-Path -Path $TestPath -ChildPath "PSScriptAnalyzer_psd1_$($TodaysDate).md")

Write-Output "Running PSScriptAnalyzer on all .ps1 files in $($srcPublicFunctionPath)..."
$PSAnalyzer = Invoke-ScriptAnalyzer -Path $srcPublicFunctionPath -Recurse -ReportSummary | select-object * | Out-File -Encoding UTF8BOM -FilePath $(Join-Path -Path $TestPath -ChildPath "PSScriptAnalyzer_ps1_$($TodaysDate).md")

# Import the module and save the Get-Help files to the $HelpPath for the module, files get saved in .md format
Write-Verbose "Importing $($ModuleName) to the session..."
Import-Module -Name $($ModuleFolderPath) -MinimumVersion $Version -Force

Write-Verbose "Writing $($ModuleName) functions to help files in $($HelpPath)..."
$mCommands = Get-Command -Module $ModuleName
foreach ($m in $mCommands) {
    if ($null -ne $m) {
        Write-Verbose "Creating help file of function $($m.Name)..."
        Get-Help -name $m.Name -Full | Out-File -Encoding UTF8BOM -FilePath $(Join-Path -Path $HelpPath -ChildPath "$($m.Name).md")
    }
}

if ($PSAnalyzer.Severity -contains "Warning" -or $PSAnalyzerPSD -contains "Warning") {
    $PSAnalyzer
    Write-Error "PSAnalyzer severity did contain Warning, please fix this and run the RSModuleBuilder again. You can se the results from PSAnalyzer above this row."
    Break
}

if ($Publish -eq $true) {
    Write-Verbose "Publishing $($ModuleName) version $($version) to PowerShell Gallery"
    Publish-Module -Path $ModuleFolderPath -NuGetApiKey $apiKey -Force
    Write-Output "---/// $($ModuleName) version $($Version) has now been built and published to PowerShell Gallery! ///---"
}
else {
    Write-Output "---/// $($ModuleName) version $($Version) is now prepared for publishing! ///---"
}