param(
    [Parameter(Mandatory=$true)]
    [string]$RegistrationToken
)

# Enable TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Define download URIs for AVD agent and bootloader
$uris = @(
    "https://go.microsoft.com/fwlink/?linkid=2310011",  # AVD Agent
    "https://go.microsoft.com/fwlink/?linkid=2311028"   # Bootloader
)

# Create a temporary directory for downloads
$tempDir = Join-Path $env:TEMP "AVDInstall"
New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
Set-Location -Path $tempDir

# Download and unblock the installers
$installers = @()
foreach ($uri in $uris) {
    try {
        $request = Invoke-WebRequest -MaximumRedirection 0 -Uri $uri -ErrorAction SilentlyContinue -UseBasicParsing
        $expandedUri = $request.Headers.Location
    } catch {
        $expandedUri = $_.Exception.Response.Headers.Location.AbsoluteUri
    }
    
    $fileName = ($expandedUri).Split('/')[-1]
    Write-Host "Downloading $fileName from $expandedUri"
    
    Invoke-WebRequest -Uri $expandedUri -OutFile $fileName -UseBasicParsing
    Unblock-File -Path $fileName
    $installers += $fileName
}

# Assign full paths for installation
$agentInstaller = $installers | Where-Object { $_ -like "*RDAgent.Installer*.msi" }
$bootloaderInstaller = $installers | Where-Object { $_ -like "*RDAgentBootLoader*.msi" }

if (-not $agentInstaller) {
    Write-Error "AVD Agent installer not found!"
    exit 1
}

if (-not $bootloaderInstaller) {
    Write-Error "AVD Bootloader installer not found!"
    exit 1
}

Write-Host "Found agent installer: $agentInstaller"
Write-Host "Found bootloader installer: $bootloaderInstaller"
Write-Host "Using registration token: $($RegistrationToken.Substring(0, 10))..."

# Install AVD Agent with the provided registration token
$agentPath = Join-Path $tempDir $agentInstaller
$agentArgs = "/i `"$agentPath`" /quiet REGISTRATIONTOKEN=`"$RegistrationToken`" /log `"$tempDir\agent-install.log`""
Write-Host "Installing AVD Agent with command: msiexec.exe $agentArgs"
$agentProcess = Start-Process msiexec.exe -ArgumentList $agentArgs -Wait -PassThru -NoNewWindow

if ($agentProcess.ExitCode -ne 0) {
    Write-Error "AVD Agent installation failed with exit code $($agentProcess.ExitCode). Check log at $tempDir\agent-install.log"
    exit 1
}

# Install Boot Loader
$bootloaderPath = Join-Path $tempDir $bootloaderInstaller
$bootloaderArgs = "/i `"$bootloaderPath`" /quiet /log `"$tempDir\bootloader-install.log`""
Write-Host "Installing AVD Bootloader with command: msiexec.exe $bootloaderArgs"
$bootloaderProcess = Start-Process msiexec.exe -ArgumentList $bootloaderArgs -Wait -PassThru -NoNewWindow

if ($bootloaderProcess.ExitCode -ne 0) {
    Write-Error "AVD Bootloader installation failed with exit code $($bootloaderProcess.ExitCode). Check log at $tempDir\bootloader-install.log"
    exit 1
}

Write-Host "AVD Agent and Bootloader installed successfully"

# Force a restart to ensure installation is complete and applied
Write-Host "Restarting in 20 seconds to complete the installation..."
Start-Sleep -Seconds 20
Restart-Computer -Force
