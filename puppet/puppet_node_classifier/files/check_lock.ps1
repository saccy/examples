#Check if puppet run lock exists
$path = 'C:\ProgramData\PuppetLabs\puppet\cache\state\agent_catalog_run.lock'

if (Test-Path $path) {
    Write-Host 'waiting'
}
else {
    exit 0
}