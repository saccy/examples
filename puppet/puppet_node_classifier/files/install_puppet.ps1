#timestamp and signature will be inserted by node_classifier.sh script

$ip   = '<your puppet master IP/hostname>'
$port = '8140'

[Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
$webClient = New-Object System.Net.WebClient
$webClient.DownloadFile("https://${ip}:${port}/packages/current/install.ps1", 'C:\Windows\Temp\install_puppet.ps1')
C:\Windows\Temp\install_puppet.ps1 `
    custom_attributes:1.3.6.1.4.1.34380.1.1.100=${ts} `
    custom_attributes:1.3.6.1.4.1.34380.1.1.101=${sig} `
    main:certname=${clientcert}
