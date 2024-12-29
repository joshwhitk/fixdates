param(
    [string]$TargetFolder
)

# this is a Windows Powershell script (fixdates.ps1) written by josh whitkin 
#
Write-Output ""
Write-Output "This script solves the problem: when you download photos from google photos via takeout or folder download, their 'date modified' is not set in EXIF metadata, so programs like Divinci Resolve can see them."
Write-Output ""
Write-Output "it works by using Exiftool to set dates in images and video files from filenames like 'IMG_20240202_whatever.mp4' so you can see Feb 2 2024 in 'Date Modified' in Davinci Resolve."
Write-Output ""
Write-Output "It can run very slowly if you have a lot of files so be patient..."

if (-not $TargetFolder) {
    Write-Output "Error: Please provide a child folder as an argument."
    exit
}

# Path to ExifTool
$exifToolPath = "C:\Program Files\exiftool\exiftool.exe"

# Ensure ExifTool is installed
if (-not (Test-Path $exifToolPath)) {
    Write-Output "ExifTool not found at $exifToolPath."
    Write-Output "Please download ExifTool from https://exiftool.org/ and place it in the specified location. Rename the exe to exiftool.exe as per its instructions."
    exit
}
Write-Output "I found exiftool the target folder okay."

# Get today's year
$today = Get-Date
$currentYear = $today.Year

# Initialize counters
$incorrectFiles = @()
$totalFiles = 0
$problemFiles = @()

# Supported file types (images and videos)
$supportedExtensions = @(".jpg", ".jpeg", ".png", ".mp4", ".mov", ".avi", ".mkv", ".heic")

# First Pass: Review files and count incorrect metadata
Get-ChildItem -Path $TargetFolder -File -Recurse | Where-Object { $supportedExtensions -contains $_.Extension.ToLower() } | ForEach-Object {
    $file = $_
    $filename = $file.BaseName

    Write-Output "working on $filename..."

    # Default datetime placeholder for files without an 8-digit date
    $datetime = "Unknown"

    # Look for 8-digit sequences in the format _YYYYMMDD_
    if ($filename -match "_([0-9]{4})([0-9]{2})([0-9]{2})_") {
        $year = $matches[1]
        $month = $matches[2]
        $day = $matches[3]

        # Ensure the year is valid (2000 <= year <= current year)
        if ($year -ge 2000 -and $year -le $currentYear) {
            $datetime = "${year}:${month}:${day} 00:00:00"
        }
    }

    # Check existing metadata
    try {
        $metadata = & "$exifToolPath" -CreateDate -S -s "$($file.FullName)"
        if ($metadata -notlike "*${datetime}*" -or $datetime -eq "Unknown") {
            $incorrectFiles += $file
        }
    } catch {
        Write-Output "Error reading metadata for $($file.FullName): $_"
        $problemFiles += $file
    }

    $totalFiles++
}

Write-Output "Total files reviewed: $totalFiles"
Write-Output "Files with incorrect metadata: $($incorrectFiles.Count)"
Write-Output "Files with metadata issues: $($problemFiles.Count)"

if ($problemFiles.Count -gt 0) {
    Write-Output "The following files have issues and cannot be processed automatically:"
    $problemFiles | ForEach-Object { Write-Output $_.FullName }
}

if ($incorrectFiles.Count -gt 0) {
    Write-Output "Press Enter to continue and update incorrect files..."
    Read-Host

    # Second Pass: Update incorrect files
    foreach ($file in $incorrectFiles) {
        $filename = $file.BaseName

        # Skip files without valid date patterns
        if ($filename -notmatch "_([0-9]{4})([0-9]{2})([0-9]{2})_") {
            Write-Output "Skipped: $($file.Name) - No valid date found in filename"
            continue
        }

        $year = $matches[1]
        $month = $matches[2]
        $day = $matches[3]

        if ($year -ge 2000 -and $year -le $currentYear) {
            $datetime = "${year}:${month}:${day} 00:00:00"

            # Update EXIF metadata using ExifTool
            try {
                & "$exifToolPath" -overwrite_original `
                    "-CreateDate=$datetime" `
                    "-FileCreateDate=$datetime" `
                    "-FileModifyDate=$datetime" `
                    "$($file.FullName)"

                Write-Output "Processed: $($file.Name) - Set date to $datetime"
            } catch {
                Write-Output "Error processing $($file.FullName): $_"
                $problemFiles += $file
            }
        } else {
            Write-Output "Skipped: $($file.Name) - Year $year is out of range"
        }
    }
}

Write-Output "Done!"
