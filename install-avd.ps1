param (
    [string]$RegistrationToken
)

# Trim any quotes
$RegistrationToken = $RegistrationToken.Trim("'")

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
        Invoke-WebRequest -Uri $uri -UseBasicParsing -OutFile $fileName -ErrorAction Stop
        Unblock-File -Path $fileName
        $installers += $fileName
        Write-Log "Downloaded and unblocked: $fileName"
    } catch {
        Write-Log "Error downloading $uri"
    }
}

# Install AVD Agent
$agentInstaller = $installers | Where-Object { $_ -like '*AVDAgent.msi' }
if ($agentInstaller) {
    Write-Log "Installing AVD Agent: $agentInstaller"
    Start-Process msiexec.exe -ArgumentList "/i `"$agentInstaller`" /quiet REGISTRATIONTOKEN=`"$RegistrationToken`"" -Wait
} else {
    Write-Log "AVD Agent installer not found"
}

# Install Bootloader
$bootloaderInstaller = $installers | Where-Object { $_ -like '*AVDBootloader.msi' }
if ($bootloaderInstaller) {
    Write-Log "Installing Bootloader: $bootloaderInstaller"
    Start-Process msiexec.exe -ArgumentList "/i `"$bootloaderInstaller`" /quiet" -Wait
} else {
    Write-Log "Bootloader installer not found"
}

Write-Log "AVD agent script execution completed"
