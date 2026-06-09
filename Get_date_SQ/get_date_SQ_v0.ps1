$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Content-Type", "application/json")

$body = "{
`n    `"auth_key`":`"c7_AG!f}2B]>m:`"
`n}"

$response = Invoke-RestMethod 'http://cnw00021.corp.int.kn:8000/api/info' -Method 'POST' -Headers $headers -Body $body
$response | ConvertTo-Json
$response.data | Export-Csv -Path "C:\temp\staff.csv" -NoTypeInformation -Encoding UTF8