cls
# 加了dedup开头不算的filter，新增删除MonitorSerialNumber为1或0的行
# Define source path and destination path
$sourcePath = $PSScriptRoot
$destinationPath = "\\fuobohid01\fuoit$\Monitor_Check\CombineCSV\"

# Use the current folder name for the output file date string
$folderName = Split-Path -Leaf $PSScriptRoot
if ($folderName -match '^(\d{4})-(\d{2})-(\d{2})$') {
    $dateString = $folderName
}
elseif ($folderName -match '^(\d{1,2})([A-Za-z]{3})(\d{4})$') {
    $monthMap = @{jan='01'; feb='02'; mar='03'; apr='04'; may='05'; jun='06'; jul='07'; aug='08'; sep='09'; oct='10'; nov='11'; dec='12'}
    $day = '{0:d2}' -f [int]$matches[1]
    $month = $monthMap[$matches[2].ToLower()]
    $year = $matches[3]
    $dateString = "$year-$month-$day"
}
else {
    $dateString = (Get-Date).ToString('yyyy-MM-dd')
}

$combinedFileName = "dedup_combine_$dateString.csv"
$combinedFilePath = Join-Path -Path $destinationPath -ChildPath $combinedFileName

# Create destination folder if it doesn't exist
if (-not (Test-Path -Path $destinationPath)) {
    New-Item -ItemType Directory -Path $destinationPath | Out-Null
}

# Get all CSV files in the source path, excluding those starting with "dedup_combine"
$csvFiles = Get-ChildItem -Path $sourcePath -Filter "*.csv" -File | 
            Where-Object { $_.Name -notlike "dedup_combine_*" }

# Check if there are any CSV files to process
if (-not $csvFiles -or $csvFiles.Count -eq 0) {
    Write-Warning "No CSV files found for processing (excluded dedup_combine_* files)"
    exit
}

# Initialize an empty array to store content
$combinedContent = @()

foreach ($csvFile in $csvFiles) {
    Write-Host "Processing file: $($csvFile.Name)"
    
    # Attempt to auto-detect delimiter (try comma first, then tab if failed)
    try {
        # First try default comma delimiter
        $content = Import-Csv -Path $csvFile.FullName -ErrorAction Stop
    }
    catch {
        Write-Warning "Failed to import with comma delimiter, trying tab delimiter for $($csvFile.Name)"
        # Try tab delimiter
        $content = Import-Csv -Path $csvFile.FullName -Delimiter "`t"
    }
    
    # 新增：过滤掉MonitorSerialNumber为1或0的行
    if ($content -and $content.Count -gt 0) {
        $filteredContent = $content | Where-Object { 
            $_.MonitorSerialNumber -ne "1" -and $_.MonitorSerialNumber -ne "0"
        }
        
        # 统计过滤情况
        $removedCount = $content.Count - $filteredContent.Count
        if ($removedCount -gt 0) {
            Write-Host "Removed $removedCount rows where MonitorSerialNumber is 1 or 0 from $($csvFile.Name)"
        }
    }
    else {
        $filteredContent = @()
    }

    # Check if data was successfully imported after filtering
    if ($filteredContent -and $filteredContent.Count -gt 0) {
        $combinedContent += $filteredContent
        Write-Host "Successfully added $($filteredContent.Count) rows from $($csvFile.Name)`n"
    }
    else {
        Write-Warning "No valid data found in $($csvFile.Name) after filtering`n"
    }
}

# Display total rows before deduplication
Write-Host "`nTotal rows before deduplication: $($combinedContent.Count)"

# Deduplicate based on specific columns
$uniqueColumns = @("UserName", "ComputerName", "MonitorSerialNumber")  # 保持原有的去重列

# Deduplicate by specified columns, keeping the first occurrence
$uniqueContent = $combinedContent | 
    Group-Object -Property $uniqueColumns -AsHashTable -AsString | 
    ForEach-Object { $_.Values | ForEach-Object { $_ | Select-Object -First 1 } }

# 按 UserName→ComputerName→DeviceType 排序
$uniqueContent = $uniqueContent | Sort-Object -Property UserName, ComputerName, DeviceType

# Display result statistics after deduplication
Write-Host "`nTotal rows after deduplication: $($uniqueContent.Count)"

# Export the result
$uniqueContent | Export-Csv -Path $combinedFilePath -NoTypeInformation -Encoding UTF8

Write-Host "`nMerge completed with duplicates removed. File saved to: $combinedFilePath"

# 暂停窗口，避免自动关闭
Read-Host -Prompt "`nPress Enter key to exit"