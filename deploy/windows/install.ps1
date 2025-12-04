# Uncrumpled Context Switcher - Windows Installation Script
# This script installs the daemon as a Windows service or user startup application

param(
    [switch]$Service,      # Install as Windows service (requires admin)
    [switch]$Startup,      # Install as user startup application
    [switch]$Uninstall,    # Remove installation
    [switch]$Help          # Show help
)

$ErrorActionPreference = "Stop"

# Configuration
$AppName = "UncrumpledContextSwitcherDaemon"
$DisplayName = "Uncrumpled Context Switcher"
$Description = "A context management daemon that acts as a central hub for application state"
$ExeName = "uncrumpled-context-switcher-daemon.exe"

# Paths
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$InstallDir = "$env:LOCALAPPDATA\uncrumpled-context-switcher"
$ConfigDir = "$env:APPDATA\uncrumpled-context-switcher"
$LogDir = "$env:LOCALAPPDATA\uncrumpled-context-switcher\logs"

function Show-Help {
    Write-Host @"
Uncrumpled Context Switcher - Windows Installation Script

Usage: install.ps1 [OPTIONS]

Options:
  -Service     Install as a Windows service (requires Administrator privileges)
  -Startup     Install as a user startup application
  -Uninstall   Remove the installation
  -Help        Show this help message

Examples:
  .\install.ps1 -Startup          Install for current user (auto-start on login)
  .\install.ps1 -Service          Install as Windows service (admin required)
  .\install.ps1 -Uninstall        Remove installation

Paths:
  Installation: $InstallDir
  Configuration: $ConfigDir\config.toml
  Logs: $LogDir\daemon.log

"@
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Ensure-Directory {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Write-Host "Created directory: $Path"
    }
}

function Create-DefaultConfig {
    $configPath = "$ConfigDir\config.toml"

    if (Test-Path $configPath) {
        Write-Host "Config file already exists: $configPath"
        return
    }

    $defaultConfig = @"
# Uncrumpled Context Switcher Configuration
# See documentation for all available options

[context]
allowed_projects = [".*"]
allowed_profiles = ["default", "work", "personal", "gaming"]
allowed_environments = ["dev", "staging", "prod", "local"]

[tags]
[[tags.definitions]]
name = "--work"
description = "Work context"

[[tags.definitions]]
name = "--personal"
description = "Personal context"

[daemon]
# Named pipe path (Windows uses named pipes instead of Unix sockets)
pipe_path = "\\.\pipe\uncrumpled-context-switcher"
heartbeat_interval_seconds = 30
subscriber_timeout_seconds = 90
max_log_entries = 1000
"@

    $defaultConfig | Out-File -FilePath $configPath -Encoding UTF8
    Write-Host "Created default config: $configPath"
}

function Install-Binary {
    # Find the binary
    $sourcePath = Join-Path $ScriptDir $ExeName

    if (-not (Test-Path $sourcePath)) {
        # Try parent directories
        $sourcePath = Join-Path (Split-Path -Parent $ScriptDir) $ExeName
        if (-not (Test-Path $sourcePath)) {
            $sourcePath = Join-Path (Split-Path -Parent (Split-Path -Parent $ScriptDir)) $ExeName
        }
    }

    if (-not (Test-Path $sourcePath)) {
        Write-Error "Cannot find $ExeName. Please build it first or place it in the same directory as this script."
        exit 1
    }

    $destPath = Join-Path $InstallDir $ExeName
    Copy-Item -Path $sourcePath -Destination $destPath -Force
    Write-Host "Installed binary: $destPath"
    return $destPath
}

function Install-AsStartup {
    Write-Host "Installing as user startup application..."

    # Create directories
    Ensure-Directory $InstallDir
    Ensure-Directory $ConfigDir
    Ensure-Directory $LogDir

    # Install binary
    $exePath = Install-Binary

    # Create config
    Create-DefaultConfig

    # Create startup shortcut
    $startupPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
    $shortcutPath = Join-Path $startupPath "$AppName.lnk"

    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $exePath
    $shortcut.WorkingDirectory = $InstallDir
    $shortcut.Description = $Description
    $shortcut.Save()

    Write-Host "Created startup shortcut: $shortcutPath"
    Write-Host ""
    Write-Host "Installation complete!"
    Write-Host ""
    Write-Host "The daemon will start automatically on next login."
    Write-Host "To start now, run: $exePath"
}

function Install-AsService {
    Write-Host "Installing as Windows service..."

    if (-not (Test-Administrator)) {
        Write-Error "Administrator privileges required to install as a service."
        Write-Error "Please run this script as Administrator."
        exit 1
    }

    # Create directories
    Ensure-Directory $InstallDir
    Ensure-Directory $ConfigDir
    Ensure-Directory $LogDir

    # Install binary
    $exePath = Install-Binary

    # Create config
    Create-DefaultConfig

    # Check if service exists
    $existingService = Get-Service -Name $AppName -ErrorAction SilentlyContinue
    if ($existingService) {
        Write-Host "Stopping existing service..."
        Stop-Service -Name $AppName -Force -ErrorAction SilentlyContinue
        Write-Host "Removing existing service..."
        sc.exe delete $AppName | Out-Null
        Start-Sleep -Seconds 2
    }

    # Create the service
    # Note: For a proper Windows service, the daemon needs to be built with service support
    # This creates a basic service that runs the executable
    $binPath = "`"$exePath`" --foreground"

    New-Service -Name $AppName `
        -DisplayName $DisplayName `
        -Description $Description `
        -BinaryPathName $binPath `
        -StartupType Automatic | Out-Null

    Write-Host "Created Windows service: $AppName"

    # Start the service
    Start-Service -Name $AppName
    Write-Host "Started service"

    Write-Host ""
    Write-Host "Installation complete!"
    Write-Host ""
    Write-Host "Service commands:"
    Write-Host "  Start:   Start-Service $AppName"
    Write-Host "  Stop:    Stop-Service $AppName"
    Write-Host "  Status:  Get-Service $AppName"
    Write-Host "  Logs:    Get-EventLog -LogName Application -Source $AppName"
}

function Uninstall {
    Write-Host "Uninstalling Uncrumpled Context Switcher..."

    # Stop and remove service if exists
    $existingService = Get-Service -Name $AppName -ErrorAction SilentlyContinue
    if ($existingService) {
        if (Test-Administrator) {
            Write-Host "Stopping service..."
            Stop-Service -Name $AppName -Force -ErrorAction SilentlyContinue
            Write-Host "Removing service..."
            sc.exe delete $AppName | Out-Null
        } else {
            Write-Warning "Service exists but need Administrator privileges to remove it."
        }
    }

    # Remove startup shortcut
    $startupPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
    $shortcutPath = Join-Path $startupPath "$AppName.lnk"
    if (Test-Path $shortcutPath) {
        Remove-Item $shortcutPath -Force
        Write-Host "Removed startup shortcut"
    }

    # Remove binary
    $exePath = Join-Path $InstallDir $ExeName
    if (Test-Path $exePath) {
        Remove-Item $exePath -Force
        Write-Host "Removed binary"
    }

    Write-Host ""
    Write-Host "Uninstallation complete!"
    Write-Host ""
    Write-Host "Configuration and logs have been preserved in:"
    Write-Host "  Config: $ConfigDir"
    Write-Host "  Logs:   $LogDir"
    Write-Host ""
    Write-Host "To remove all data, manually delete these directories."
}

# Main logic
if ($Help) {
    Show-Help
    exit 0
}

if ($Uninstall) {
    Uninstall
    exit 0
}

if ($Service) {
    Install-AsService
    exit 0
}

if ($Startup) {
    Install-AsStartup
    exit 0
}

# Default: show help
Show-Help
