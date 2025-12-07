# Uncrumpled Context Switcher - Windows Installation Script
# This script installs the daemon as a Windows service or user startup application

param(
    [switch]$Service,      # Install as Windows service (requires admin)
    [switch]$Startup,      # Install as user startup application
    [switch]$Update,       # Update binaries only (preserve config, restart service)
    [switch]$Dev,          # Development mode (build + update, no service restart)
    [switch]$Uninstall,    # Remove installation
    [switch]$Help          # Show help
)

$ErrorActionPreference = "Stop"

# Configuration
$AppName = "UncrumpledContextSwitcherDaemon"
$DisplayName = "Uncrumpled Context Switcher"
$Description = "A context management daemon that acts as a central hub for application state"
$DaemonExeName = "uncrumpled-context-switcher-daemon.exe"
$UIExeName = "uncrumpled-context-switcher.exe"
$CLIExeName = "uncrumpled-context-switcher-cli.exe"

# Paths
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)
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
  -Update      Update binaries only (preserve config, restart service)
  -Dev         Development mode (build + update, no service restart)
  -Uninstall   Remove the installation
  -Help        Show this help message

Examples:
  .\install.ps1 -Startup          Install for current user (auto-start on login)
  .\install.ps1 -Service          Install as Windows service (admin required)
  .\install.ps1 -Update           Update binaries, preserve config, restart service
  .\install.ps1 -Dev              Quick rebuild and update for development
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

function Test-ExistingInstall {
    $daemonPath = Join-Path $InstallDir $DaemonExeName
    return Test-Path $daemonPath
}

function Ensure-Directory {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Write-Host "Created directory: $Path"
    }
}

function Prompt-HotkeySelection {
    Write-Host ""
    Write-Host "Select a global hotkey to toggle the Context Switcher UI:"
    Write-Host ""
    Write-Host "  1) Ctrl+Alt+P          (default, recommended)"
    Write-Host "  2) Ctrl+Shift+Space"
    Write-Host "  3) Win+P               (Windows key + P)"
    Write-Host "  4) F12"
    Write-Host "  5) None                (disable hotkey)"
    Write-Host "  6) Custom              (configure manually in config.toml)"
    Write-Host ""

    $choice = Read-Host "Enter your choice [1-6] (default: 1)"
    if ([string]::IsNullOrEmpty($choice)) { $choice = "1" }

    switch ($choice) {
        "1" {
            $script:HotkeyEnabled = "true"
            $script:HotkeyKey = "P"
            $script:HotkeyModifiers = "Ctrl+Alt"
            Write-Host "Selected: Ctrl+Alt+P"
        }
        "2" {
            $script:HotkeyEnabled = "true"
            $script:HotkeyKey = "Space"
            $script:HotkeyModifiers = "Ctrl+Shift"
            Write-Host "Selected: Ctrl+Shift+Space"
        }
        "3" {
            $script:HotkeyEnabled = "true"
            $script:HotkeyKey = "P"
            $script:HotkeyModifiers = "Win"
            Write-Host "Selected: Win+P"
        }
        "4" {
            $script:HotkeyEnabled = "true"
            $script:HotkeyKey = "F12"
            $script:HotkeyModifiers = ""
            Write-Host "Selected: F12"
        }
        "5" {
            $script:HotkeyEnabled = "false"
            $script:HotkeyKey = ""
            $script:HotkeyModifiers = ""
            Write-Host "Selected: None (hotkey disabled)"
        }
        "6" {
            $script:HotkeyEnabled = "true"
            $script:HotkeyKey = ""
            $script:HotkeyModifiers = ""
            Write-Host "Selected: Custom (edit config.toml to set your hotkey)"
        }
        default {
            $script:HotkeyEnabled = "true"
            $script:HotkeyKey = "P"
            $script:HotkeyModifiers = "Ctrl+Alt"
            Write-Host "Invalid choice, using default: Ctrl+Alt+P"
        }
    }
    Write-Host ""
}

function Create-DefaultConfig {
    param([switch]$Force)

    $configPath = "$ConfigDir\config.toml"

    if ((Test-Path $configPath) -and -not $Force) {
        Write-Host "Preserving existing config: $configPath"
        return
    }

    # Prompt for hotkey selection
    Prompt-HotkeySelection

    $defaultConfig = @"
# Uncrumpled Context Switcher Configuration
# See documentation for all available options

[context]
allowed_projects = [".*"]
allowed_profiles = ["default", "work", "personal", "gaming"]
allowed_environments = ["dev", "staging", "prod", "local"]

[[tags.definitions]]
name = "--work"
description = "Work context"

[[tags.definitions]]
name = "--personal"
description = "Personal context"

[daemon]
# Named pipe path (Windows uses named pipes instead of Unix sockets)
# Note: Use single quotes for literal strings in TOML (no escape processing)
pipe_path = '\\\\.\\pipe\\uncrumpled-context-switcher'
heartbeat_interval_seconds = 30
subscriber_timeout_seconds = 90
max_log_entries = 1000

[hotkey]
# Global hotkey to toggle the Context Switcher UI
enabled = $script:HotkeyEnabled
key = "$script:HotkeyKey"
modifiers = "$script:HotkeyModifiers"
"@

    # Write without BOM (UTF8NoBOM) - PowerShell 5.1 doesn't have UTF8NoBOM, so use .NET
    [System.IO.File]::WriteAllText($configPath, $defaultConfig, [System.Text.UTF8Encoding]::new($false))
    Write-Host "Created default config: $configPath"
}

function Find-Binaries {
    # Returns hashtable of found binaries
    $binaries = @{
        Daemon = $null
        UI = $null
        CLI = $null
    }

    # Check bin directory first (preferred)
    $binDir = Join-Path $ProjectRoot "bin"
    if (Test-Path $binDir) {
        $daemonPath = Join-Path $binDir $DaemonExeName
        $uiPath = Join-Path $binDir $UIExeName
        $cliPath = Join-Path $binDir $CLIExeName

        if (Test-Path $daemonPath) { $binaries.Daemon = $daemonPath }
        if (Test-Path $uiPath) { $binaries.UI = $uiPath }
        if (Test-Path $cliPath) { $binaries.CLI = $cliPath }
    }

    # Fallback to script directory
    if (-not $binaries.Daemon) {
        $localPath = Join-Path $ScriptDir $DaemonExeName
        if (Test-Path $localPath) { $binaries.Daemon = $localPath }
    }

    return $binaries
}

function Build-Project {
    Write-Host "Development mode: Building project..."
    Write-Host ""

    # Check for jai compiler
    $jaiPath = Get-Command jai -ErrorAction SilentlyContinue
    if (-not $jaiPath) {
        Write-Error "Error: 'jai' compiler not found in PATH"
        exit 1
    }

    Push-Location $ProjectRoot
    try {
        $result = jai build.jai 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Build failed"
            Write-Host $result
            exit 1
        }
        Write-Host "Build successful!"
        Write-Host ""
    }
    finally {
        Pop-Location
    }
}

function Install-Binaries {
    $binaries = Find-Binaries

    if (-not $binaries.Daemon) {
        Write-Host "Error: Daemon binary not found"
        Write-Host ""
        Write-Host "Searched locations:"
        Write-Host "  $ProjectRoot\bin\$DaemonExeName"
        Write-Host ""
        Write-Host "Please build the project first:"
        Write-Host "  cd $ProjectRoot"
        Write-Host "  jai build.jai"
        Write-Host ""
        Write-Host "Or use -Dev mode to build and install in one step:"
        Write-Host "  .\install.ps1 -Dev"
        exit 1
    }

    # Install daemon (required)
    $daemonDest = Join-Path $InstallDir $DaemonExeName
    Copy-Item -Path $binaries.Daemon -Destination $daemonDest -Force
    Write-Host "Installed daemon: $daemonDest"

    # Install UI (optional)
    if ($binaries.UI) {
        $uiDest = Join-Path $InstallDir $UIExeName
        Copy-Item -Path $binaries.UI -Destination $uiDest -Force
        Write-Host "Installed UI: $uiDest"
    }

    # Install CLI (optional)
    if ($binaries.CLI) {
        $cliDest = Join-Path $InstallDir $CLIExeName
        Copy-Item -Path $binaries.CLI -Destination $cliDest -Force
        Write-Host "Installed CLI: $cliDest"
    }

    return $daemonDest
}

function Stop-RunningProcess {
    # Stop any running processes
    $processes = Get-Process -Name "uncrumpled-context-switcher*" -ErrorAction SilentlyContinue
    if ($processes) {
        Write-Host "Stopping running processes..."
        $processes | Stop-Process -Force
        Start-Sleep -Seconds 1
    }
}

function Install-AsStartup {
    param([switch]$UpdateOnly, [switch]$DevMode)

    if ($UpdateOnly) {
        Write-Host "Update Mode: Binaries only (preserving configuration)"
    }
    if ($DevMode) {
        Write-Host "Dev Mode: No service restart"
    }
    Write-Host "Installing as user startup application..."

    # Create directories
    Ensure-Directory $InstallDir
    Ensure-Directory $ConfigDir
    Ensure-Directory $LogDir

    # Stop running processes before update (unless dev mode)
    $wasRunning = $false
    if (-not $DevMode) {
        $processes = Get-Process -Name "uncrumpled-context-switcher*" -ErrorAction SilentlyContinue
        if ($processes) {
            $wasRunning = $true
            Stop-RunningProcess
        }
    }

    # Install binaries
    $daemonPath = Install-Binaries

    # Create config (skip in update mode)
    if (-not $UpdateOnly) {
        Create-DefaultConfig
    }

    # Create startup shortcut (skip in update mode)
    if (-not $UpdateOnly) {
        $startupPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
        $shortcutPath = Join-Path $startupPath "$AppName.lnk"

        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $daemonPath
        $shortcut.WorkingDirectory = $InstallDir
        $shortcut.Description = $Description
        $shortcut.Save()

        Write-Host "Created startup shortcut: $shortcutPath"
    }

    Write-Host ""
    Write-Host "Installation complete!"
    Write-Host ""

    if ($UpdateOnly) {
        if ($DevMode) {
            Write-Host "Binaries updated. Process was not restarted (dev mode)."
            Write-Host ""
            Write-Host "To manually start:"
            Write-Host "  Start-Process `"$daemonPath`""
        } else {
            if ($wasRunning) {
                Write-Host "Restarting application..."
                Start-Process -FilePath $daemonPath -WorkingDirectory $InstallDir
                Write-Host "Binaries updated and application restarted."
            } else {
                Write-Host "Binaries updated. Application was not running."
            }
        }
    } else {
        Write-Host "The daemon will start automatically on next login."
        Write-Host "To start now, run: $daemonPath"
    }
}

function Install-AsService {
    param([switch]$UpdateOnly, [switch]$DevMode)

    if ($UpdateOnly) {
        Write-Host "Update Mode: Binaries only (preserving configuration)"
    }
    if ($DevMode) {
        Write-Host "Dev Mode: No service restart"
    }
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

    # Check if service was running
    $existingService = Get-Service -Name $AppName -ErrorAction SilentlyContinue
    $wasRunning = $false
    if ($existingService -and $existingService.Status -eq 'Running') {
        $wasRunning = $true
        if (-not $DevMode) {
            Write-Host "Stopping existing service..."
            Stop-Service -Name $AppName -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
        }
    }

    # Install binaries
    $daemonPath = Install-Binaries

    # Create config (skip in update mode)
    if (-not $UpdateOnly) {
        Create-DefaultConfig
    }

    # Create/update service (skip in update mode)
    if (-not $UpdateOnly) {
        if ($existingService) {
            Write-Host "Removing existing service..."
            sc.exe delete $AppName | Out-Null
            Start-Sleep -Seconds 2
        }

        # Create the service
        $binPath = "`"$daemonPath`" --foreground"

        New-Service -Name $AppName `
            -DisplayName $DisplayName `
            -Description $Description `
            -BinaryPathName $binPath `
            -StartupType Automatic | Out-Null

        Write-Host "Created Windows service: $AppName"
    }

    Write-Host ""
    Write-Host "Installation complete!"
    Write-Host ""

    if ($UpdateOnly) {
        if ($DevMode) {
            Write-Host "Binaries updated. Service was not restarted (dev mode)."
            Write-Host ""
            Write-Host "To manually restart:"
            Write-Host "  Restart-Service $AppName"
        } else {
            if ($wasRunning) {
                Write-Host "Restarting service..."
                Start-Service -Name $AppName
                Write-Host "Binaries updated and service restarted."
            } else {
                Write-Host "Binaries updated. Service was not running."
            }
        }
    } else {
        # Start the service
        Start-Service -Name $AppName
        Write-Host "Started service"
        Write-Host ""
        Write-Host "Service commands:"
        Write-Host "  Start:   Start-Service $AppName"
        Write-Host "  Stop:    Stop-Service $AppName"
        Write-Host "  Status:  Get-Service $AppName"
        Write-Host "  Logs:    Get-EventLog -LogName Application -Source $AppName"
    }
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

    # Stop any running processes
    Stop-RunningProcess

    # Remove startup shortcut
    $startupPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
    $shortcutPath = Join-Path $startupPath "$AppName.lnk"
    if (Test-Path $shortcutPath) {
        Remove-Item $shortcutPath -Force
        Write-Host "Removed startup shortcut"
    }

    # Remove binaries
    $daemonPath = Join-Path $InstallDir $DaemonExeName
    $uiPath = Join-Path $InstallDir $UIExeName
    $cliPath = Join-Path $InstallDir $CLIExeName
    if (Test-Path $daemonPath) {
        Remove-Item $daemonPath -Force
        Write-Host "Removed binary: $daemonPath"
    }
    if (Test-Path $uiPath) {
        Remove-Item $uiPath -Force
        Write-Host "Removed binary: $uiPath"
    }
    if (Test-Path $cliPath) {
        Remove-Item $cliPath -Force
        Write-Host "Removed binary: $cliPath"
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

# Dev mode: build first
if ($Dev) {
    Build-Project
    $Update = $true
}

# Update mode: verify existing installation
if ($Update) {
    if (-not (Test-ExistingInstall)) {
        Write-Error "Error: -Update specified but no existing installation found"
        Write-Host ""
        Write-Host "Run without -Update for fresh installation:"
        Write-Host "  .\install.ps1 -Startup"
        Write-Host "  .\install.ps1 -Service"
        exit 1
    }

    # Detect installation type and update accordingly
    $existingService = Get-Service -Name $AppName -ErrorAction SilentlyContinue
    if ($existingService) {
        Install-AsService -UpdateOnly -DevMode:$Dev
    } else {
        Install-AsStartup -UpdateOnly -DevMode:$Dev
    }
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
