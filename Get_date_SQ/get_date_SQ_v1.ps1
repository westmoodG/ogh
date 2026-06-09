$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Content-Type", "application/json")

$body = "{
`n    `"auth_key`":`"c7_AG!f}2B]>m:`"
`n}"

$response = Invoke-RestMethod 'http://cnw00021.corp.int.kn:8000/api/info' -Method 'POST' -Headers $headers -Body $body
$response | ConvertTo-Json
if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
    Install-Module -Name ImportExcel -Scope CurrentUser -Force -Confirm:$false
}
Import-Module ImportExcel -ErrorAction Stop
$response.data | Export-Excel -Path ("C:\temp\FUO_Staff_{0}.xlsx" -f (Get-Date -Format 'yyyyMMdd')) -WorksheetName 'Staff' -AutoSize
