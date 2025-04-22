# Enable TLS 1.2 for secure downloads
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Download AVD agent installer
Invoke-WebRequest -Uri "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv" -OutFile "AVDAgent.msi"

# Download side-by-side stack installer
Invoke-WebRequest -Uri "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH" -OutFile "AVDStack.msi"

# Install AVD agent
Start-Process msiexec.exe -Wait -ArgumentList "/i AVDAgent.msi /quiet"

# Install AVD side-by-side stack
Start-Process msiexec.exe -Wait -ArgumentList "/i AVDStack.msi /quiet"

# Get the registration token from custom data (passed as base64 encoded content)
$token = Get-Content -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\customdata.txt"

# Register session host
Start-Process -Wait -FilePath "C:\Program Files\Microsoft RDInfra\RDInfraAgent\RDInfraAgent.exe" -ArgumentList "join $token"
