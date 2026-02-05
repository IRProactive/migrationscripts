<#
.SYNOPSIS
    Downloads and installs CrowdStrike Falcon sensor from internal share
.DESCRIPTION
    This script copies the CrowdStrike installer from a network share,
    installs it with the required CID, and logs the process.
.NOTES
    Requires: Administrator privileges
    Author: IR Proacctive
    Date: 2026-01-23
#>

# Requires -RunAsAdministrator

# Configuration
$shareSource = "\\file-server\IT\Security\CrowdStrike\WindowsSensor.exe"
$localPath = "$env:TEMP\WindowsSensor.exe"
$logFile = "$env:TEMP\CrowdStrike_Install_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$cid = "YOUR_CUSTOMER_ID_HERE"  # Replace with your actual CID

# Function to write log entries
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Tee-Object -FilePath $logFile -Append
}

try {
    Write-Log "Starting CrowdStrike Falcon sensor installation"
    
    # Check if running as Administrator
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "This script must be run as Administrator"
    }
    
    # Copy installer from share
    Write-Log "Copying installer from $shareSource to $localPath"
    if (-not (Test-Path $shareSource)) {
        throw "Source file not found: $shareSource"
    }
    
    Copy-Item -Path $shareSource -Destination $localPath -Force
    Write-Log "Installer copied successfully"
    
    # Verify file exists locally
    if (-not (Test-Path $localPath)) {
        throw "Failed to copy installer to local path"
    }
    
    # Install CrowdStrike Falcon sensor
    Write-Log "Installing CrowdStrike Falcon sensor with CID: $cid"
    $installArgs = "/install /quiet /norestart CID=$cid"
    
    $process = Start-Process -FilePath $localPath -ArgumentList $installArgs -Wait -PassThru -NoNewWindow
    
    if ($process.ExitCode -eq 0) {
        Write-Log "CrowdStrike Falcon sensor installed successfully (Exit Code: 0)"
    } else {
        Write-Log "Installation completed with exit code: $($process.ExitCode)"
    }
    
    # Cleanup installer
    Write-Log "Cleaning up installer file"
    Remove-Item -Path $localPath -Force -ErrorAction SilentlyContinue
    
    Write-Log "Installation process completed"
    Write-Log "Log file location: $logFile"
    
} catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    throw

}
