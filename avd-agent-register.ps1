param (
    [string]$token
)

# Enable TLS 1.2 for secure web requests
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Download the AVD Agent
Invoke-WebRequest -Uri "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv" -OutFile "AVDAgent.msi"

# Download the AVD Side-by-Side Stack
Invoke-WebRequest -Uri "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH" -OutFile "AVDStack.msi"

# Install AVD Agent silently
Start-Process msiexec.exe -Wait -ArgumentList "/i AVDAgent.msi /quiet"

# Install AVD Stack silently
Start-Process msiexec.exe -Wait -ArgumentList "/i AVDStack.msi /quiet"

# Register the VM to the AVD Host Pool using the token
$Path = "$env:ProgramFiles\Microsoft RDInfra\RDAgentBootLoader"
if (Test-Path "$Path\RDAgentBootLoader.exe") {
    cd $Path
    .\RDAgentBootLoader.exe /Join:$token
} else {
    Write-Error "RDAgentBootLoader.exe not found at $Path"
}
