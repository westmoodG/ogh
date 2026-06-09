# Define source path (folder where the current script is located) and destination path
$sourcePath = $PSScriptRoot  # Automatically gets the folder path of the current .ps1 file
$destinationPath = "\\fuobohid01\fuoit$\Monitor_Check\CombineCSV\"

# Get today's date and format it
# $dateString = (Get-Date).ToString("ddMMMyyyy")  # e.g.: 27Aug2024
$dateString = (Get-Item -Path $sourcePath).Name
$combinedFileName = "combine_$dateString.csv"
$combinedFilePath = Join-Path -Path $destinationPath -ChildPath $combinedFileName

# Create destination folder if it doesn't exist
if (-not (Test-Path -Path $destinationPath)) {
    New-Item -ItemType Directory -Path $destinationPath | Out-Null
}

# Get all CSV files in the source path and combine them
$csvFiles = Get-ChildItem -Path $sourcePath -Filter "*.csv" -File  # Only get files, exclude directories
$totalFiles = $csvFiles.Count  # Total number of CSV files
$currentFileIndex = 0  # Current file index (starts from 1)

# Initialize an empty array to store content
$combinedContent = @()

foreach ($csvFile in $csvFiles) {
    $currentFileIndex++  # Increment index for each file
    # Show progress (e.g., 11/ 300)
    Write-Host "Processing file $currentFileIndex/$totalFiles : $($csvFile.Name)" -ForegroundColor Cyan

    # Import CSV file content
    $content = Import-Csv -Path $csvFile.FullName
    # Add content to the array
    $combinedContent += $content
}

# Export the combined content to a new CSV file
$combinedContent | Export-Csv -Path $combinedFilePath -NoTypeInformation -Encoding UTF8

Write-Host "`nMerge completed. Total files processed: $totalFiles" -ForegroundColor Green
Write-Host "File saved to: $combinedFilePath"

# 暂停窗口，避免自动关闭
Read-Host -Prompt "`nPress any key to exit"