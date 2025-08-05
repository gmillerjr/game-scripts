# ======================== CONFIGURATION ========================
# Folder mappings: source => destination
$folderMappings = @(
    @{ Source = "what to monitor"; Destination = "where the copy should go" },
    @{ Source = "what to monitor"; Destination = "where the copy should go" },
    @{ Source = "what to monitor"; Destination = "where the copy should go" },
    @{ Source = "what to monitor"; Destination = "where the copy should go" },
    @{ Source = "what to monitor"; Destination = "where the copy should go" }
)

# File types to watch for in the source ie .exe .pdf, etc
$fileExtensions = @(".arkprofile", ".arkprofiletemp")

# File types to archive after a certain age (cleanup)
$cleanupExtensions = @(".arkprofiletemp")

# Cleanup age threshold for .arkprofiletemp files (in days) See line 116
$cleanupAgeDays = 7

# How often to scan folders (in seconds)
$pollIntervalSeconds = 60

# Where to store state of already-seen files
$seenFilesPath = "$PSScriptRoot\seenFiles.json"
# ===============================================================


# ======================= INITIAL SETUP =========================
# Show current folder mappings
$folderMappings | Format-Table Source, Destination

# Ensure destination folders exist
foreach ($map in $folderMappings) {
    if (-not $map.Source -or -not $map.Destination) {
        Write-Warning "Missing source or destination in a mapping: $($map | Out-String)"
        continue
    }

    if (-not (Test-Path $map.Source)) {
        Write-Warning "Source folder does not exist: $($map.Source)"
    }

    if (-not (Test-Path $map.Destination)) {
        try {
            New-Item -ItemType Directory -Path $map.Destination -Force | Out-Null
        } catch {
            Write-Warning "Failed to create destination folder: $($map.Destination)"
        }
    }
}
# ===============================================================


# ================ LOAD SEEN FILES (STATE TRACKING) ==============
$seenFiles = @{}

if (Test-Path $seenFilesPath) {
    $json = Get-Content $seenFilesPath -Raw

    if ($PSVersionTable.PSVersion.Major -ge 7) {
        $seenFiles = ConvertFrom-Json -InputObject $json -AsHashtable
    } else {
        $tempFiles = ConvertFrom-Json -InputObject $json
        foreach ($key in $tempFiles.PSObject.Properties.Name) {
            $seenFiles[$key] = $tempFiles.$key
        }
    }
}
# ===============================================================


# ======================= MAIN MONITOR LOOP ======================
while ($true) {
    foreach ($map in $folderMappings) {
        $sourceFolder = $map.Source
        $destFolder   = $map.Destination

        if (-not (Test-Path $sourceFolder) -or -not (Test-Path $destFolder)) {
            Write-Warning "Skipping: $sourceFolder or $destFolder is missing."
            continue
        }

        # Get matching files in source folder
        $files = Get-ChildItem -Path $sourceFolder -File | Where-Object {
            $fileExtensions -contains $_.Extension.ToLower()
        }

        foreach ($file in $files) {
            $fullPath = $file.FullName

            # Only copy new files
            if (-not $seenFiles.ContainsKey($fullPath)) {
                $timestamp = Get-Date -Format "yyyy-MM-dd_HHmm"
                $newFileName = "$timestamp-$($file.Name)"
                $destinationPath = Join-Path $destFolder $newFileName

                try {
                    Copy-Item -Path $fullPath -Destination $destinationPath -Force

                    # Log copy action
                    $logEntry = "$($timestamp): Copied $($file.Name) to $destinationPath"
                    Add-Content -Path (Join-Path $destFolder "copy_log.txt") -Value $logEntry
                    Write-Host $logEntry

                    # Track as seen
                    $seenFiles[$fullPath] = $true
                } catch {
                    Write-Warning "Failed to copy '$($file.FullName)' to '$destinationPath': $_"
                }
            }
        }

        # =================== CLEANUP (ARCHIVE) ===================
		# Moves files with the specific extension to the archive folder
$archiveFolder = Join-Path $destFolder "archive"
if (-not (Test-Path $archiveFolder)) {
    New-Item -ItemType Directory -Path $archiveFolder | Out-Null
}

Get-ChildItem -Path $destFolder -File | Where-Object {
    $cleanupExtensions -contains $_.Extension.ToLower() -and
    $_.LastWriteTime -lt (Get-Date).AddDays(-$cleanupAgeDays)
} | ForEach-Object {
    $destArchivePath = Join-Path $archiveFolder $_.Name

    try {
        Move-Item -Path $_.FullName -Destination $destArchivePath -Force
        Write-Host "Moved old file to archive: $($_.Name)"
    } catch {
        Write-Warning "Failed to archive '$($_.FullName)': $_"
    }
}
        # =========================================================
    }

    # Save current seen files list to disk used to track what files have been reviewed already
    $seenFiles | ConvertTo-Json | Set-Content -Path $seenFilesPath

    # Wait before next poll
    Start-Sleep -Seconds $pollIntervalSeconds
}
# ===============================================================
