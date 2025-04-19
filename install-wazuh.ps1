Start-Sleep -Seconds 60

try {
    $msiPath = "C:\wazuh-agent-4.11.2.msi"
    $managerIP = "10.0.1.4"
    $logFile = "C:\wazuh-install.log"

    # Download latest Wazuh agent
    Invoke-WebRequest -Uri "https://packages.wazuh.com/4.x/windows/wazuh-agent-4.11.2-1.msi" -OutFile $msiPath -UseBasicParsing
    Add-Content -Path $logFile -Value "Downloaded Wazuh agent MSI at $(Get-Date)"

    # Install silently with manager IP
    Start-Process msiexec.exe -ArgumentList "/i `"$msiPath`" /qn WAZUH_MANAGER=$managerIP" -Wait
    Add-Content -Path $logFile -Value "Executed MSI installer at $(Get-Date)"

    Start-Sleep -Seconds 15

    # Start Wazuh service if it exists
    if (Get-Service -Name WazuhSvc -ErrorAction SilentlyContinue) {
        Start-Service WazuhSvc
        Add-Content -Path $logFile -Value "Wazuh agent installed and started at $(Get-Date)"
    } else {
        Add-Content -Path $logFile -Value "Wazuh service not found after install at $(Get-Date)"
    }
}
catch {
    Add-Content -Path "C:\wazuh-install.log" -Value "Installation failed at $(Get-Date): $_"
}
