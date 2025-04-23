# install-avd.ps1
$downloadPath = "C:\Temp"
if (-Not (Test-Path $downloadPath)) {
    New-Item -Path $downloadPath -ItemType Directory -Force | Out-Null
}

$uris = @(
    "https://go.microsoft.com/fwlink/?linkid=2310011",  # AVD Agent
    "https://go.microsoft.com/fwlink/?linkid=2311028"   # Bootloader
)

$installers = @()
foreach ($uri in $uris) {
    $expandedUri = (Invoke-WebRequest -MaximumRedirection 0 -Uri $uri -ErrorAction SilentlyContinue).Headers.Location
    $fileName = ($expandedUri).Split("/")[-1]
    $outFile = Join-Path $downloadPath $fileName
    Invoke-WebRequest -Uri $expandedUri -UseBasicParsing -OutFile $outFile
    Unblock-File -Path $outFile
    $installers += $outFile
}

$agentInstaller = $installers | Where-Object { $_ -like '*RDAgent.Installer*.msi' }
if ($agentInstaller) {
    Start-Process msiexec.exe -ArgumentList "/i `"$agentInstaller`" /quiet REGISTRATIONTOKEN=`"${env:AVD_REG_TOKEN}`"" -Wait
}

$bootloaderInstaller = $installers | Where-Object { $_ -like '*RDAgentBootLoader*.msi' }
if ($bootloaderInstaller) {
    Start-Process msiexec.exe -ArgumentList "/i `"$bootloaderInstaller`" /quiet" -Wait
}
