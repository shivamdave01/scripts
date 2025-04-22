# Enable TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Define download URIs
$uris = @(
    "https://go.microsoft.com/fwlink/?linkid=2310011",  # Agent
    "https://go.microsoft.com/fwlink/?linkid=2311028"   # Bootloader
)

# Download and unblock installers
$installers = @()
foreach ($uri in $uris) {
    $expandedUri = (Invoke-WebRequest -MaximumRedirection 0 -Uri $uri -ErrorAction SilentlyContinue).Headers.Location
    $fileName = ($expandedUri).Split('/')[-1]
    Invoke-WebRequest -Uri $expandedUri -OutFile $fileName -UseBasicParsing
    Unblock-File -Path $fileName
    $installers += $fileName
}

# Install AVD Agent with token
$token = "${env:REGISTRATIONTOKEN}"  # Terraform will pass it in via protected settings
Start-Process msiexec.exe -Wait -ArgumentList "/i Microsoft.RDInfra.RDAgent.Installer-x64.msi /quiet REGISTRATIONTOKEN=$token"

# Install Boot Loader
Start-Process msiexec.exe -Wait -ArgumentList "/i Microsoft.RDInfra.RDAgentBootLoader.Installer-x64.msi /quiet"
