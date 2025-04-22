# Enable TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Define download URIs for AVD agent and bootloader
$uris = @(
    "https://go.microsoft.com/fwlink/?linkid=2310011",  # AVD Agent
    "https://go.microsoft.com/fwlink/?linkid=2311028"   # Bootloader
)

# Download and unblock the installers
$installers = @()
foreach ($uri in $uris) {
    $expandedUri = (Invoke-WebRequest -MaximumRedirection 0 -Uri $uri -ErrorAction SilentlyContinue).Headers.Location
    $fileName = ($expandedUri).Split('/')[-1]
    Invoke-WebRequest -Uri $expandedUri -OutFile $fileName -UseBasicParsing
    Unblock-File -Path $fileName
    $installers += $fileName
}

# Assign full paths for installation
$agentInstaller = $installers | Where-Object { $_ -like "*RDAgent.Installer-x64-1.0.10673.700.msi" }
$bootloaderInstaller = $installers | Where-Object { $_ -like "*RDAgentBootLoader.Installer-x64-1.0.9023.1100.msi" }

# Get token from Terraform via environment variable (passed by Custom Script Extension)
$token = "${env:REGISTRATIONTOKEN}"

# Install AVD Agent
Start-Process msiexec.exe -Wait -ArgumentList "/i `"$agentInstaller`" /quiet REGISTRATIONTOKEN=$token"

# Install Boot Loader
Start-Process msiexec.exe -Wait -ArgumentList "/i `"$bootloaderInstaller`" /quiet"
