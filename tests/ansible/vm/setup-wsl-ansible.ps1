# IMPORTANT: This script may need TWO reboots
# - First after enabling WSL
# - Second after installing the WSL distro (not sure about this one)

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

Write-Host "[1/5] Checking WSL feature..." -ForegroundColor Yellow
$wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
if ($wslFeature.State -ne "Enabled") {
    Write-Host "Enabling WSL feature (Microsoft-Windows-Subsystem-Linux)..." -ForegroundColor Yellow
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

    Write-Host ""
    Write-Host "=== REBOOT REQUIRED ===" -ForegroundColor Red
    Write-Host "WSL feature has been enabled." -ForegroundColor Green
    Write-Host "After reboot, run this script again to continue setup." -ForegroundColor Yellow
    Write-Host ""
    $reboot = Read-Host "Reboot now? (y/n)"
    if ($reboot -eq 'y') {
        Restart-Computer -Force
    }
    exit 0
} else {
    Write-Host "WSL feature already enabled" -ForegroundColor Green
}

Write-Host ""
Write-Host "[2/5] Setting WSL default version to 1..." -ForegroundColor Yellow
Write-Host "WSL 1 does not require Hyper-V, so it works in VirtualBox VMs" -ForegroundColor Cyan
try {
    wsl --set-default-version 1 2>$null
    Write-Host "WSL default version set to 1" -ForegroundColor Green
} catch {
    Write-Host "Note: wsl command will work after Debian is installed" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[3/5] Checking for Debian..." -ForegroundColor Yellow
$debianInstalled = $false
try {
    $wslList = wsl --list --quiet 2>$null
    if ($wslList -match "Debian") {
        Write-Host "Debian already installed" -ForegroundColor Green
        $debianInstalled = $true
    }
} catch {
    # WSL not installed yet
}

if (-not $debianInstalled) {
    Write-Host ""
    Write-Host "[4/5] Installing Debian..." -ForegroundColor Yellow

    $tempDir = "C:\temp"
    if (-not (Test-Path $tempDir)) {
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    }

    $debianUrl = "https://aka.ms/wsl-debian-gnulinux"
    $debianPath = "$tempDir\debian.appx"

    Write-Host "Downloading Debian from Microsoft Store..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri $debianUrl -OutFile $debianPath -UseBasicParsing
        Write-Host "Download complete" -ForegroundColor Green
    } catch {
        Write-Host "ERROR: Failed to download Debian" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        exit 1
    }

    Write-Host "Installing Debian..." -ForegroundColor Yellow
    try {
        Add-AppxPackage -Path $debianPath
        Write-Host "Debian installed successfully" -ForegroundColor Green
    } catch {
        Write-Host "ERROR: Failed to install Debian" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        exit 1
    }

    Write-Host ""
    Write-Host "Initializing Debian (this will open a new window)..." -ForegroundColor Yellow
    Write-Host "When prompted, create a username and password" -ForegroundColor Cyan
    Write-Host "Press Enter to continue..." -ForegroundColor Yellow
    Read-Host

    Start-Process "debian.exe" -ArgumentList "install --root" -NoNewWindow -Wait
    Write-Host "Debian initialized with root user" -ForegroundColor Green
} else {
    Write-Host "[4/5] Debian already installed, skipping" -ForegroundColor Green
}

Write-Host ""
Write-Host "[5/5] Installing Ansible + pywinrm in Debian..." -ForegroundColor Yellow

$ansibleInstallScript = @'
echo "Updating package list..."
apt-get update -qq

echo "Installing dependencies..."
apt-get install -y python3 python3-pip curl

echo "Installing Ansible and pywinrm..."
pip3 install --quiet ansible pywinrm

echo ""
echo "Verifying installation..."
ansible --version
echo ""
echo "Installation complete!"
'@

Write-Host "Running installation in WSL Debian..." -ForegroundColor Yellow
$ansibleInstallScript | wsl -d Debian -u root -- bash

Write-Host ""
Write-Host "Creating test files..." -ForegroundColor Yellow

$testInventory = @"
---
all:
  hosts:
    localhost:
      ansible_connection: local
      ansible_become_method: runas
"@

Set-Content -Path "C:\temp\test-inventory.yml" -Value $testInventory -Force

$testPlaybook = @"
---
- name: Test Ansible on Windows from WSL
  hosts: localhost
  gather_facts: yes

  tasks:
    - name: Display Windows version
      debug:
        msg: "Windows version: {{ ansible_distro }} {{ ansible_distro_version }}"

    - name: Check if Chocolatey is installed
      win_shell: |
        if (Get-Command choco -ErrorAction SilentlyContinue) {
          choco --version
        } else {
          Write-Output "not_installed"
        }
      register: choco_check

    - name: Display Chocolatey status
      debug:
        msg: "{{ choco_check.stdout_lines }}"

    - name: Install test package via Chocolatey
      win_chocolatey:
        name: git
        state: present
      when: choco_check.stdout is not search("not_installed")
"@

Set-Content -Path "C:\temp\test-playbook.yml" -Value $testPlaybook -Force
