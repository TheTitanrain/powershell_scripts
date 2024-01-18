# Script checking AD group changes in the last 24 hours and sends notification to Telegram
# Author: TitanRain
$LogPath = "C:\windows\temp\send_notification_about_group_change.log"
"Script started at $(Get-Date)" | Out-File -Append $LogPath

$time = (get-date) - (new-timespan -hour 24)
$tg_token="xxxxx"
$tg_chat_id="xxxxx"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

"Getting domain controllers" | Out-File -Append $LogPath
$DCs = Get-ADDomainController -Filter *
"Domain contrillers: $DCs" | Out-File -Append $LogPath
"Iterate through domain controllers" | Out-File -Append $LogPath
foreach ($DC in $DCs){
    "Processing $DC" | Out-File -Append $LogPath
    $result = Get-WinEvent -ComputerName $DC -FilterHashtable @{logname='Security';id=4732,4728;StartTime=$Time} -ErrorAction SilentlyContinue| ForEach-Object {
        $eventXml = ([xml]$_.ToXml()).Event
        [PSCustomObject]@{
            TimeCreated   = $eventXml.System.TimeCreated.SystemTime -replace '\.\d+.*$'
            User = $eventXml.EventData.Data[0]."#text"
            Group = $eventXml.EventData.Data[2]."#text"
            WhoChanged = $eventXml.EventData.Data[6]."#text"
            Computer = $eventXml.System.Computer
        }
    }
    $Error | Out-File -Append $LogPath
    "Events: $result" | Out-File -Append $LogPath
    If ($result)
    {
        "Events found. Sending to Telegram." | Out-File -Append $LogPath
        $text= $result|ConvertTo-Json
        $response = Invoke-RestMethod -Uri "https://api.telegram.org/bot$($tg_token)/sendMessage?chat_id=$($tg_chat_id)&text=$($text)&parse_mode=html"
        "Sending response: $($response)" | Out-File -Append $LogPath
    }
}
"Script finished at $(Get-Date)" | Out-File -Append $LogPath
