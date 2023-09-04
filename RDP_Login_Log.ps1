$rdpEvents = Get-WinEvent -FilterHashtable @{Logname='Security'; ID=4624, 4625} |
    ForEach-Object {
        $xml = [xml]$_.ToXml()
        $ip = $xml.Event.EventData.Data |
            Where-Object {$_.Name -eq 'IpAddress'} |
            Select-Object -ExpandProperty '#text'
        $status = if ($_.Id -eq 4624) { "Success" } else { "Failure" }
        [PSCustomObject]@{
            IPAddress = $ip
            Status = $status
        }
    }

# 접속 시도한 IP 주소들을 그룹화하여 성공, 실패 횟수와 시도 횟수를 계산합니다.
# Group the IP addresses that attempted to access to calculate success, failure, and number of attempts.
$ipCounts = $rdpEvents | Group-Object -Property IPAddress | ForEach-Object {
    $attempts = $_.Group.Count
    $successes = ($_.Group | Where-Object { $_.Status -eq "Success" }).Count
    $failures = $attempts - $successes
    [PSCustomObject]@{
        IPAddress = $_.Name
        AttemptCount = $attempts
        SuccessCount = $successes
        FailureCount = $failures
    }
} | Sort-Object -Property AttemptCount -Descending

# 결과를 txt 파일로 저장
# Save results as a txt file
$logFolder = "C:\Users\Desktop\Logs"
$logFileName = "$(Get-Date -Format 'yyyy-MM-dd-HH-mm-ss').txt"
$logFile = Join-Path $logFolder $logFileName
$ipCounts | Format-Table -AutoSize | Out-File $logFile
