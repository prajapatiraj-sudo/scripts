# Prompt user for source Tally folder
$sourceFolder = Read-Host "Enter the full path of the Tally folder you want to clone (e.g., C:\OriginalTally)"

# Check if the source folder exists
if (-Not (Test-Path $sourceFolder)) {
    Write-Host "The folder '$sourceFolder' does not exist. Please check the path and try again."
    exit
}

# Prompt user for number of clones
$cloneCount = Read-Host "How many Tally clones do you want to create?"

# Prompt for destination folder base path
$baseDestFolder = Read-Host "Enter the base destination folder path for the clones (e.g., C:\TallyClone)"

# Prompt for updating Tally.ini
$updateIni = Read-Host "Do you want to update the Tally.ini file in each clone? (Yes/No)"
$updateIni = $updateIni -eq "Yes"

# Function to generate incremented paths
function Increment-Path {
    param (
        [string]$basePath,
        [int]$index
    )
    # Extract the last folder name and increment it
    $folderParts = $basePath -split '\\'
    $folderParts[-1] = "$($folderParts[-1])$index"
    return ($folderParts -join '\')
}

# Function to modify .ini file
function Update-TallyIni {
    param (
        [string]$iniPath,
        [string]$dataPath,
        [string]$configPath
    )

    # Update .ini content based on user input
    (Get-Content $iniPath) |
        ForEach-Object {
            if ($_ -match '^Data=.*') {
                $_ = "Data=$dataPath"
            } elseif ($_ -match '^Config=.*') {
                $_ = "Config=$configPath"
            }
            $_
        } | Set-Content $iniPath
}

# Ask user for the base paths if updating .ini
if ($updateIni) {
    $baseDataPath = Read-Host "Enter the base Data path (e.g., C:\FileManager\Data)"
    $baseConfigPath = Read-Host "Enter the base Tally Setting path (e.g., C:\Tally)"
}

# Loop for creating clones
for ($i = 1; $i -le $cloneCount; $i++) {
    $destFolder = "$baseDestFolder$i"
    $dataPath = if ($updateIni) { Increment-Path -basePath $baseDataPath -index $i } else { $null }
    $configPath = if ($updateIni) { Increment-Path -basePath $baseConfigPath -index $i } else { $null }

    # Clone folder
    Copy-Item -Path $sourceFolder -Destination $destFolder -Recurse

    # If updating .ini is required
    if ($updateIni) {
        $iniPath = "$destFolder\tally.ini"

        # Check if Tally.ini exists
        if (Test-Path $iniPath) {
            # Update .ini file with incremented paths
            Update-TallyIni -iniPath $iniPath -dataPath $dataPath -configPath $configPath
        } else {
            Write-Host "Tally.ini file not found in $destFolder. Skipping update."
        }
    }
}

Write-Host "Tally cloning process completed successfully!"
