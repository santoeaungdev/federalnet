<#
PowerShell helper to copy rad dump to VPS. Edit variables below.
Usage: Open PowerShell and run this script.
#>
$vpsIp = '143.110.185.159'
$vpsUser = 'root'
$vpsPort = 22
$localFile = 'docker\\tmp_dump\\rad_dump.sql'
$remotePath = '/root/rad_dump.sql'

Write-Host "Copying $localFile -> $vpsUser@$vpsIp:$remotePath (port $vpsPort)"
scp -P $vpsPort $localFile $vpsUser@$vpsIp:$remotePath
