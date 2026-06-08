# 新增：如果BIOS序列号以VMware开头（不区分大小写），直接退出脚本（优化后版本）
$computerBIOS = Get-CimInstance Win32_BIOS
if ($computerBIOS.SerialNumber -match '^(?i)vmware') {
    Write-Host "VMware虚拟机，无需收集信息，脚本退出。" -ForegroundColor Yellow
    exit 0  # 正常退出，退出码0
}

# Get current date and format as "ddMMMyyyy" (compatible with older PowerShell versions)
$months = @("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")
$today = Get-Date
$currentDate = "{0:d2}{1}{2}" -f $today.Day, $months[$today.Month - 1], $today.Year

# Build base path
$basePath = "\\fuobohid01\fuoit$\Monitor_Check\$currentDate"

# Check if folder exists, create if not
if (-not (Test-Path -Path $basePath)) {
    New-Item -Path $basePath -ItemType Directory -Force | Out-Null
}

# v2
$sourceFile = "\\fuobohid01\fuoit$\Script\_combine_csv_2.ps1"
if (-not (Test-Path (Join-Path $basePath (Split-Path $sourceFile -Leaf)) -PathType Leaf)) {
   Copy-Item $sourceFile $basePath -ErrorAction SilentlyContinue 
   }

# Get system information
# $computerBIOS = Get-CimInstance Win32_BIOS
$computerSystem = Get-CimInstance Win32_ComputerSystem
$computerMonitor = Get-CimInstance WmiMonitorID -Namespace root\wmi

# Get username
$myusername = ($computerSystem).username -split "\\" | Select-Object -Last 1
if (-not $myusername) {
    $myusername = ((gcim win32_userprofile | ?{$_.loaded -eq 1 -and $_.Special -eq 0}).localpath).split("\")[2]
}

# Get active IPv4 addresses for the computer
$ipAddresses = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Where-Object { $_.IPAddress -notmatch '^(127|169\.254)\.' -and $_.InterfaceAlias -notmatch 'vEthernet|Loopback|Teredo' } |
    Select-Object -ExpandProperty IPAddress

if (-not $ipAddresses) {
    $ipAddresses = Get-CimInstance Win32_NetworkAdapterConfiguration |
        Where-Object { $_.IPEnabled -and $_.IPAddress } |
        ForEach-Object { $_.IPAddress } |
        Where-Object { $_ -match '^\d{1,3}(\.\d{1,3}){3}$' -and $_ -notmatch '^(127|169\.254)\.' }
}

$ipAddresses = @($ipAddresses) -join '; '

# Modify UserName based on conditions
if ($myusername -eq "apple.wang" -and $computerBIOS.SerialNumber -ne "1P547M3") {
    $myusername = "apple.wang.k"
} elseif ($myusername -eq "windy.li" -and $computerBIOS.SerialNumber -ne "14G8XC4") {
    $myusername = "windy.li.k"
} elseif ($myusername -eq "jerry.chen" -and $computerBIOS.SerialNumber -ne "3MD8XC4") {
    $myusername = "jerry.chen.k"
} elseif ($myusername -eq "leo.jiang" -and $computerBIOS.SerialNumber -ne "4LS9H24") {
    $myusername = "leo.jiang.k"
} elseif ($myusername -eq "ryan.lin" -and $computerBIOS.SerialNumber -ne "2MD8XC4") {
    $myusername = "ryan.lin.k"
} elseif ($myusername -eq "jack.ou" -and $computerBIOS.SerialNumber -ne "13HZS44") {
    $myusername = "Nobody"
}

# Computer basic information
$basicInfo = [PSCustomObject]@{
    'UserName' = $myusername
    'ComputerName' = $computerSystem.Name
    'ComManufacturer' = $computerSystem.Manufacturer
    'ComputerModel' = $computerSystem.Model
    'ComputerServiceTag' = $computerBIOS.SerialNumber
    'IPAddress' = $ipAddresses
    'MonManufacturerName' = $null
    'MonitorModel' = $null
    'MonitorSerialNumber' = $null
    'DeviceType' = 'Computer'
}

# Collect monitor information
$monitorData = foreach ($monitor in $computerMonitor) {
    $monManufacturer = [System.Text.Encoding]::ASCII.GetString($monitor.ManufacturerName)
    $monSerial = [System.Text.Encoding]::ASCII.GetString($monitor.SerialNumberID)
    
    if ($monitor.userfriendlyname -and $monitor.userfriendlyname.Length -gt 0) {
        $monModel = [System.Text.Encoding]::ASCII.GetString($monitor.userfriendlyname)
    } else {
        $monModel = "Unknown Model"
    }

    [PSCustomObject]@{
        'UserName' = $myusername
        'ComputerName' = $computerSystem.Name
        'ComManufacturer' = $computerSystem.Manufacturer
        'ComputerModel' = $computerSystem.Model
        'ComputerServiceTag' = $computerBIOS.SerialNumber
        'IPAddress' = $ipAddresses
        'MonManufacturerName' = $monManufacturer
        'MonitorModel' = $monModel
        'MonitorSerialNumber' = $monSerial
        'DeviceType' = 'Monitor'
    }
}

# Combine all data (computer info + monitor info)
$allData = @($basicInfo) + $monitorData

# Build file name
$monitorSerials = $monitorData | ForEach-Object { $_.MonitorSerialNumber }
$serialString = ($monitorSerials -join '_') -replace '[^\w]', ''
$mypath = "$basePath\$($myusername)_$($computerSystem.Name)_$serialString.csv" -replace '[^\w$\\.:]', ''

$allData

# Export to CSV
if (Test-Path $mypath) { Remove-Item $mypath -Force }
$allData | Export-Csv -Path $mypath -NoTypeInformation -Force

Write-Host "Information collection completed, saved to: $mypath" -ForegroundColor Green