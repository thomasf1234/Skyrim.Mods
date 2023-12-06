# Requires Powershell 7

param (
    [Parameter(Mandatory=$true)][string] $ModName,
    [string] $Action = $( Read-Host "Please choose install[i] or un-install[u]" )
)

function Create-DirectoryIfNotExists($Path) {
    if (!(Test-Path $Path)) {
        New-Item -Path $Path -ItemType Directory | Out-Null
    }
}

If ($Action -ne "i" -And $Action -ne "u") {
     Write-Output "Invalid action, please choose i or u." 
     return
}


$SkyrimPath = "C:\Program Files (x86)\Steam\steamapps\common\Skyrim Special Edition"
# $SkyrimPath = "Skyrim Special Edition"
$ModPath = "ManualMods/${ModName}"
$AddedDirPath = "${ModPath}/Added"
$ReplacedDirPath = "${ModPath}/Replaced"

if ($Action -eq "i")
{
    if (Test-Path $ModPath) {
        Write-Error "Mod needs to be uninstalled first" 
        return
    }

    # Try Uninstall First by checking Added and Replaced directories
    # Afterward delete them and unzip to start a fresh installation
    $ZipPath = "${ModName}.zip"

    if (!(Test-Path $ZipPath)) {
        Write-Error "Zip not found ${ZipPath}" 
        return
    }

    $Zip = Get-Item $ZipPath
    Create-DirectoryIfNotExists "ManualMods"
    Expand-Archive -LiteralPath $ZipPath -DestinationPath "ManualMods/${ModName}"
    Rename-Item "ManualMods/${ModName}/${ModName}" "Added"

    
    Create-DirectoryIfNotExists $ReplacedDirPath

    $FilesToAdd = Get-ChildItem -Path $AddedDirPath -Recurse -Force -File
    foreach ($File in $FilesToAdd) {   
        $RelativePath = Resolve-Path -Relative -RelativeBasePath $AddedDirPath -Path $File.FullName
        $DestPath = Join-Path -Path $SkyrimPath -ChildPath $RelativePath
        $DestDirPath = Split-Path -Parent -Path $DestPath
        if (!(Test-Path $DestDirPath)) {
            New-Item -Path $DestDirPath -ItemType Directory | Out-Null
        }

        if (Test-Path $DestPath)
        {
            Write-Output "Backing up file before overwriting: ${DestPath}" 

            # Backup first
            $BackupPath = Join-Path -Path $ReplacedDirPath -ChildPath $RelativePath
            $BackupDirPath = Split-Path -Parent -Path $BackupPath

            if (!(Test-Path $BackupDirPath)) {
                Write-Output "Creating backup directory if not exists: ${BackupDirPath}" 
                New-Item -Path $BackupDirPath -ItemType Directory | Out-Null
            }

            Copy-Item -Path $DestPath -Destination $BackupPath -Force

            Write-Output "Backing up replaced file to: ${BackupPath}" 
            
            if (!(Test-Path $BackupPath)) {
                Write-Error "Failed to backup file to: ${BackupPath}"
                return
            }
        }

        Copy-Item -Path $File.FullName -Destination $DestPath -Force
    }
}
else 
{    
    if (!(Test-Path $ModPath)) {
        Write-Error "Mod is not installed" 
        return
    }

    # Delete all added files first
    $FilesToDelete = Get-ChildItem -Path $AddedDirPath -Recurse -Force -File
    foreach ($File in $FilesToDelete) {   
        $RelativePath = Resolve-Path -Relative -RelativeBasePath $AddedDirPath -Path $File.FullName
        $DestPath = Join-Path -Path $SkyrimPath -ChildPath $RelativePath
        
        if (Test-Path $DestPath)
        {
            Write-Output "Deleting file: ${DestPath}" 
            Remove-Item $DestPath

            if (Test-Path $DestPath) {
                Write-Error "Failed to uninstall file to: ${DestPath}"
                return
            }
        }
    }

    # Restore backed up files
    $FilesToRestore = Get-ChildItem -Path $ReplacedDirPath -Recurse -Force -File
    foreach ($File in $FilesToRestore) {   
        $RelativePath = Resolve-Path -Relative -RelativeBasePath $ReplacedDirPath -Path $File.FullName
        $DestPath = Join-Path -Path $SkyrimPath -ChildPath $RelativePath

        Write-Output "Restoring file: ${DestPath}" 
        Copy-Item -Path $File.FullName -Destination $DestPath -Force
    }

    Remove-Item -Recurse $ModPath
}

