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

# Get registration token from CustomScriptExtension protected setting
$scriptPath = "C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\*\Downloads\*\ProtectedSettings.json"
$settingsJson = Get-Content -Path (Get-ChildItem -Path $scriptPath -ErrorAction SilentlyContinue | Select-Object -First 1).FullName | ConvertFrom-Json
$token = $settingsJson.token

# Register the session host
Start-Process -Wait -FilePath "C:\Program Files\Microsoft RDInfra\RDInfraAgent\RDInfraAgent.exe" -ArgumentList "join $token"
