param(
    [Parameter(Mandatory=$true)]
    [string]$RegistrationToken
)

Write-Host "Starting AVD Agent installation process at $(Get-Date)"

# Enable TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Write-Host "TLS 1.2 enabled"

# Create the C:\Temp directory if it doesn't exist
if (!(Test-Path -Path "C:\Temp")) {
    New-Item -Path "C:\Temp" -ItemType Directory -Force | Out-Null
}

# Start Transcript for detailed logging
Start-Transcript -Path "C:\Temp\avd-agent-install-transcript.log" -Force

# Set working directory to C:\Temp
Set-Location -Path "C:\Temp"
Write-Host "Set working directory to C:\Temp"

# Define download URIs for AVD agent and bootloader
$uris = @(
    "https://go.microsoft.com/fwlink/?linkid=2310011",  # AVD Agent
    "https://go.microsoft.com/fwlink/?linkid=2311028"   # Bootloader
)
Write-Host "Defined download URIs for AVD agent and bootloader"

# Download and unblock the installers
$installers = @()
foreach ($uri in $uris) {
    Write-Host "Processing URI: $uri"
    try {
        $request = Invoke-WebRequest -MaximumRedirection 0 -Uri $uri -ErrorAction SilentlyContinue -UseBasicParsing
        $expandedUri = $request.Headers.Location
        Write-Host "Got redirect URL via request: $expandedUri"
    } catch {
        $expandedUri = $_.Exception.Response.Headers.Location.AbsoluteUri
        Write-Host "Got redirect URL via exception: $expandedUri"
    }
    
    $fileName = ($expandedUri).Split('/')[-1]
    Write-Host "Downloading $fileName from $expandedUri"
    
    try {
        Invoke-WebRequest -Uri $expandedUri -OutFile "C:\Temp\$fileName" -UseBasicParsing
        Write-Host "Download completed for $fileName"
        Unblock-File -Path "C:\Temp\$fileName"
        Write-Host "File unblocked: $fileName"
        $installers += $fileName
    }
    catch {
        Write-Error "Failed to download $expandedUri. Error: $_"
        Stop-Transcript
        exit 1
    }
}

# Assign full paths for installation
$agentInstaller = $installers | Where-Object { $_ -like "*RDAgent.Installer*.msi" }
$bootloaderInstaller = $installers | Where-Object { $_ -like "*RDAgentBootLoader*.msi" }

if (-not $agentInstaller) {
    Write-Error "AVD Agent installer not found!"
    Stop-Transcript
    exit 1
}

if (-not $bootloaderInstaller) {
    Write-Error "AVD Bootloader installer not found!"
    Stop-Transcript
    exit 1
}

Write-Host "Found agent installer: $agentInstaller"
Write-Host "Found bootloader installer: $bootloaderInstaller"
Write-Host "Using registration token starting with: $($RegistrationToken.Substring(0, 10))..."

# Save registration token to a file for troubleshooting
$RegistrationToken | Out-File -FilePath "C:\Temp\registration-token.txt" -Force

# Install AVD Agent with the provided registration token
$agentPath = Join-Path "C:\Temp" $agentInstaller
$agentArgs = "/i `"$agentPath`" /quiet REGISTRATIONTOKEN=`"$RegistrationToken`" /log `"C:\Temp\agent-install.log`""
Write-Host "Installing AVD Agent with command: msiexec.exe $agentArgs"
$agentProcess = Start-Process msiexec.exe -ArgumentList $agentArgs -Wait -PassThru -NoNewWindow

Write-Host "AVD Agent installer completed with exit code: $($agentProcess.ExitCode)"
if ($agentProcess.ExitCode -ne 0) {
    Write-Error "AVD Agent installation failed with exit code $($agentProcess.ExitCode). Check log at C:\Temp\agent-install.log"
    Stop-Transcript
    exit 1
}

# Install Boot Loader
$bootloaderPath = Join-Path "C:\Temp" $bootloaderInstaller
$bootloaderArgs = "/i `"$bootloaderPath`" /quiet /log `"C:\Temp\bootloader-install.log`""
Write-Host "Installing AVD Bootloader with command: msiexec.exe $bootloaderArgs"
$bootloaderProcess = Start-Process msiexec.exe -ArgumentList $bootloaderArgs -Wait -PassThru -NoNewWindow

Write-Host "AVD Bootloader installer completed with exit code: $($bootloaderProcess.ExitCode)"
if ($bootloaderProcess.ExitCode -ne 0) {
    Write-Error "AVD Bootloader installation failed with exit code $($bootloaderProcess.ExitCode). Check log at C:\Temp\bootloader-install.log"
    Stop-Transcript
    exit 1
}

Write-Host "AVD Agent and Bootloader installed successfully"

# Final checks
$rdAgentService = Get-Service -Name RDAgentBootLoader -ErrorAction SilentlyContinue
if ($rdAgentService) {
    Write-Host "RDAgentBootLoader service status: $($rdAgentService.Status)"
} else {
    Write-Host "RDAgentBootLoader service not found!"
}

Stop-Transcript

# Restart to finalize setup
Write-Host "Restarting in 20 seconds to complete the installation..."
Start-Sleep -Seconds 20
Restart-Computer -Force
