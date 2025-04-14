Start-Sleep -Seconds 60
try {
    $msiPath = "C:\wazuh-agent.msi"
    Invoke-WebRequest -Uri "https://packages.wazuh.com/4.x/windows/wazuh-agent-4.7.5-1.msi" -OutFile $msiPath -UseBasicParsing
    Add-Content -Path "C:\wazuh-install.log" -Value "Downloaded MSI at $(Get-Date)"

    Start-Process msiexec.exe -ArgumentList "/i `"$msiPath`" /qn WAZUH_MANAGER=10.0.1.4" -Wait

    Start-Sleep -Seconds 15

    if (Get-Service -Name WazuhSvc -ErrorAction SilentlyContinue) {
        Start-Service WazuhSvc
        Add-Content -Path "C:\wazuh-install.log" -Value "Wazuh agent installed and started at $(Get-Date)"
    } else {
        Add-Content -Path "C:\wazuh-install.log" -Value "Wazuh service not found after install at $(Get-Date)"
    }
}
catch {
    Add-Content -Path "C:\wazuh-install.log" -Value "Installation failed at $(Get-Date): $_"
}
