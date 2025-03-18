# ----------------------------------------------------------------------------
# File: phlingerize.ps1
# Add phlinger single player settings to ARK game configuration
# phlingerize.ps1 <sourceFileName> <targetDirectory>
# * sourceFileName = GameUserSettings-ASA.ini, GameUserSettings-ASA-Server.ini
# * targetDirectory = C:\Program Files (x86)\Steam\steamapps\common\ARK Survival Ascended\ShooterGame\Saved\Config\Windows
# or
# * sourceFileName = GameUserSettings-ASE.ini, GameUserSettings-ASE-Server.ini
# * targetDirectory = C:\Program Files (x86)\Steam\steamapps\common\ARK\ShooterGame\Saved\Config\WindowsNoEditor
# ----------------------------------------------------------------------------
param (
    [string]$srcFilePath,
    [string]$tgtFileDir
)

function Get-IniContent {
    param (
        [string]$filePath
    )

    $iniFile = @{}
    $section = "NO_SECTION"
    $content = Get-Content -Path $filePath

    foreach ($line in $content) {
        # Remove leading and trailing whitespace
        $line = $line.Trim()

        if (-not $line) { continue }  # Skip empty lines
        if ($line.StartsWith(";") -or $line.StartsWith("#")) { continue }  # Skip comments

        if ($line -match "^\[(.+)\]$") {
            # Found a new section
            $section = $matches[1]
            if (-not $iniFile.ContainsKey($section)) {
                $iniFile[$section] = @{}
            }
        } else {
            # Found a key-value pair
            if ($line -match "^([^=]+)=(.*)$") {
                $key = $matches[1].Trim()
                $value = $matches[2].Trim()

                # Check if the section already contains the key and handle duplicates
                if ($iniFile[$section].ContainsKey($key)) {
                    # Convert single value to array for multiple values
                    if (-not ($iniFile[$section][$key] -is [array])) {
                        $iniFile[$section][$key] = @($iniFile[$section][$key])
                    }
                    $iniFile[$section][$key] += $value
                } else {
                    $iniFile[$section][$key] = $value
                }
            }
        }
    }

    return $iniFile
}

function FindOrCreateSection {
    param (
        [System.Collections.Hashtable]$ini,
        [string]$section
    )
    foreach ($k in $ini.Keys) {
        if ($k -ieq $section) {
            return $ini[$k]
        }
    }
    $ini[$section] = @{}
    return $ini[$section]
}

# Check if the file name is provided as a parameter
if (-not $srcFilePath -or [string]::IsNullOrEmpty($srcFilePath) -or -not $tgtFileDir -or [string]::IsNullOrEmpty($tgtFileDir)) {
    Write-Error "Please provide the required parameters."
    $scriptName = $MyInvocation.MyCommand.Name
    Write-Output "Usage: $scriptName <sourceFileName> <targetDirectory>"
    Write-Output "Where sourceFileName is the name of the file containing the values to be applied"
    Write-Output "and targetDirectory is the configuration directory to apply it to"
    Write-Output ""
    Write-Output "The target file name is derived from the source file name and a copy of the original is made, e.g. 'GameUserSettings.ini-prephlingerize'."
    Write-Output ""
    Write-Output "Examples:"
    Write-Output "$scriptName 'GameUserSettings-ASA.ini' 'C:\Program Files (x86)\Steam\steamapps\common\ARK Survival Ascended\ShooterGame\Saved\Config\Windows'"
    Write-Output "$scriptName 'GameUserSettings-ASE.ini' 'C:\Program Files (x86)\Steam\steamapps\common\ARK\ShooterGame\Saved\Config\WindowsNoEditor'"
    exit 1
}

# Check if the source exists
if (-not (Test-Path $srcFilePath)) {
    Write-Error "The file '$srcFilePath' does not exist."
    exit 1
}

# Check if the target directory exists
if (-not (Test-Path $tgtFileDir)) {
    Write-Error "The directory '$tgtFileDir' does not exist."
    exit 1
}

# Load source for patches
$srcContent = Get-IniContent -filePath $srcFilePath
$pattern="([a-zA-Z]*)-[a-zA-Z-_]*(\.[iI][nN][iI])$"
$matches = $srcFilePath | Select-String -Pattern $pattern -AllMatches

$matchedCount = $matches.Matches.Count
if($matchedCount -eq 1) {
  $matchedGroups = $matches.Matches[0].Groups.Count
}
else {
  $matchedGroups = 0
}

if($matchedCount -eq 1 -and $matchedGroups -eq 3) {
  $arkIniFileName = $tgtFileDir + "\" + $matches.Matches[0].Groups[1].Value+$matches.Matches[0].Groups[2].Value
  $backupFileName = $tgtFileDir + "\" + $matches.Matches[0].Groups[1].Value+$matches.Matches[0].Groups[2].Value+"-prephlingerize"
}
else {
  Write-Error "Can't parse $srcFilePath"
  exit 1
}

if (-not (Test-Path $arkIniFileName)) {
  Write-Error "Target file $arkIniFileName not found"
  exit 1
}

$arkIniContent = Get-IniContent -filePath $arkIniFileName

$confirm = Read-Host -Prompt "Are you sure you want to update $arkIniFileName with the contents of ${srcFilePath}? (y/n)"
if ($confirm -ne "y") {
    Write-Output "Action cancelled"
    exit 1
}

if (-not (Test-Path $backupFileName)) {
  Write-Output "Copy '$arkIniFileName' to '$backupFileName' . . ."
  Copy-Item -Path $arkIniFileName -Destination $backupFileName
  Write-Output ""
}

# Iterate over all sections and key-value pairs
foreach ($section in $srcContent.Keys) {
    Write-Output "Section: [$section]"

    $iniSection = FindOrCreateSection -ini $arkIniContent -section $section
    $iniSectionCount = $iniSection.Count

    foreach ($keyValue in $srcContent[$section].GetEnumerator()) {
        $matchKV = $null
        foreach ($kv in $iniSection.GetEnumerator()) {
            if ($kv.Key -ieq $keyValue.Key) {
                $matchKV = $kv
                break
            }
        }

        if( $matchKV -ne $null ) {
            if(-not ( $matchKV.Value -ieq $keyValue.Value) ) {
                Write-Output "Update: $($matchKV.Key)=$($keyValue.Value) (Old:$($matchKV.Value))"
                $iniSection[$matchKV.Key] = $keyValue.Value
            }
            else {
                Write-Output "Unchanged: $($matchKV.Key)=$($matchKV.Value)"
            }
        }
        else {
            Write-Output "Add: $($keyValue.Key)=$($keyValue.Value)"
            $iniSection[$keyValue.Key] = $keyValue.Value
        }
    }
}

$newIniContent = ""
foreach ($section in $arkIniContent.Keys) {
    $newIniContent = $newIniContent + "[$section]`n"
    foreach ($keyValue in $arkIniContent[$section].GetEnumerator()) {
        if ($keyValue.Value -is [array]) {
            foreach ($value in $keyValue.Value) {
                $newIniContent = $newIniContent + "$($keyValue.Key)=$($value)`n"
            }
        } else {
            $newIniContent = $newIniContent + "$($keyValue.Key)=$($keyValue.Value)`n"
        }
    }
    $newIniContent = $newIniContent + "`n"
}

# Write-Output "$newIniContent"
Set-Content -Path $arkIniFileName -Value $newIniContent
