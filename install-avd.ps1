# install-avd.ps1
$ErrorActionPreference = "Stop"
$downloadPath = "C:\Temp"
if (-Not (Test-Path $downloadPath)) {
    New-Item -Path $downloadPath -ItemType Directory -Force | Out-Null
}
$logFile = "$downloadPath\avd_install.log"
function Write-Log {
    param($message)
    "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $message" | Out-File -Append -FilePath $logFile
    Write-Host $message
}

Write-Log "Starting AVD agent installation..."

# Check if registration token is provided
if (-not $env:AVD_REG_TOKEN) {
    Write-Log "ERROR: Registration token not provided"
    exit 1
}

# URLs and friendly names
$downloads = @(
    @{ Uri = "https://go.microsoft.com/fwlink/?linkid=2310011"; FileName = "AVDAgent.msi" },
    @{ Uri = "https://go.microsoft.com/fwlink/?linkid=2311028"; FileName = "AVDBootloader.msi" }
)

$installers = @()
foreach ($item in $downloads) {
    $uri = $item.Uri
    $fileName = Join-Path $downloadPath $item.FileName
    try {
        Write-Log "Downloading from $uri"
        $response = Invoke-WebRequest -Uri $uri -MaximumRedirection 0 -ErrorAction SilentlyContinue -UseBasicParsing
        
        if ($response.StatusCode -eq 302) {
            $redirectUrl = $response.Headers.Location
            Write-Log "Following redirect to: $redirectUrl"
            Invoke-WebRequest -Uri $redirectUrl -UseBasicParsing -OutFile $fileName -ErrorAction Stop
        } else {
            Invoke-WebRequest -Uri $uri -UseBasicParsing -OutFile $fileName -ErrorAction Stop
        }
        
        Unblock-File -Path $fileName
        $installers += $fileName
        Write-Log "Downloaded and unblocked: $fileName"
    } catch {
        Write-Log "Error downloading $uri"
    }
}

# Verify we have both installers
if ($installers.Count -lt 2) {
    Write-Log "ERROR: Failed to download all required installers"
    exit 1
}

# Install AVD Agent
$agentInstaller = $installers | Where-Object { $_ -like '*AVDAgent.msi' }
if ($agentInstaller) {
    Write-Log "Installing AVD Agent: $agentInstaller"
    $process = Start-Process msiexec.exe -ArgumentList "/i `"$agentInstaller`" /quiet REGISTRATIONTOKEN=`"$env:AVD_REG_TOKEN`"" -Wait -PassThru
    if ($process.ExitCode -ne 0) {
        Write-Log "ERROR: AVD Agent installation failed with exit code: $($process.ExitCode)"
        exit $process.ExitCode
    }
    Write-Log "AVD Agent installed successfully"
} else {
    Write-Log "ERROR: AVD Agent installer not found"
    exit 1
}

# Install Bootloader
$bootloaderInstaller = $installers | Where-Object { $_ -like '*AVDBootloader.msi' }
if ($bootloaderInstaller) {
    Write-Log "Installing Bootloader: $bootloaderInstaller"
    $process = Start-Process msiexec.exe -ArgumentList "/i `"$bootloaderInstaller`" /quiet" -Wait -PassThru
    if ($process.ExitCode -ne 0) {
        Write-Log "ERROR: Bootloader installation failed with exit code: $($process.ExitCode)"
        exit $process.ExitCode
    }
    Write-Log "Bootloader installed successfully"
} else {
    Write-Log "ERROR: Bootloader installer not found"
    exit 1
}

Write-Log "AVD agent script execution completed successfully"
exit 0
