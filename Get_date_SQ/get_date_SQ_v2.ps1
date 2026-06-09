<#
.SYNOPSIS
FUO staff info API export to Excel
AUTHOR: jack.ou
#>
# Configuration
$apiUri = 'http://cnw00021.corp.int.kn:8000/api/info'
$authKey = 'c7_AG!f}2B]>m:'
$outputBasePath = 'C:\temp'
$filePrefix = 'FUO_Staff'
$worksheetName = 'Staff'
$timeoutSec = 30

$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

try {
    Write-Host "[1/4] Initializing output directory..."
    if (-not (Test-Path $outputBasePath)) {
        New-Item -Path $outputBasePath -ItemType Directory -Force | Out-Null
        Write-Host "Directory created: $outputBasePath"
    }

    Write-Host "[2/4] Checking ImportExcel module..."
    if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
        Install-Module -Name ImportExcel -Scope CurrentUser -Force -Confirm:$false -AllowClobber
    }
    Import-Module ImportExcel -ErrorAction Stop
    Write-Host "ImportExcel module loaded."

    Write-Host "[3/4] Calling API..."
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Content-Type", "application/json")
    $bodyObj = @{ auth_key = $authKey }
    $bodyJson = $bodyObj | ConvertTo-Json -Compress

    $response = Invoke-RestMethod -Uri $apiUri -Method Post -Headers $headers -Body $bodyJson -TimeoutSec $timeoutSec -ErrorAction Stop
    Write-Host "API response received."

    if ($response.status -ne "success") {
        throw "API status failure: $($response.status)"
    }
    if (-not $response.data -or $response.data.Count -eq 0) {
        throw "API returned no data."
    }
    Write-Host "API request success, records: $($response.data.Count)"

    Write-Host "[4/4] Exporting to Excel..."
    $dateStamp = Get-Date -Format 'yyyyMMdd'
    $excelPath = Join-Path -Path $outputBasePath -ChildPath "$filePrefix`_$dateStamp.xlsx"

    $response.data | Export-Excel `
        -Path $excelPath `
        -WorksheetName $worksheetName `
        -AutoSize `
        -TableName "StaffList_$dateStamp" `
        -FreezeTopRow `
        -AutoFilter `
        -ClearSheet

    Write-Host "Execution complete."
    Write-Host "Excel file path: $excelPath"
    Write-Host "Exported records: $($response.data.Count)"
}
catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.InnerException) {
        Write-Host "Inner exception: $($_.Exception.InnerException.Message)" -ForegroundColor DarkRed
    }
    exit 1
}
