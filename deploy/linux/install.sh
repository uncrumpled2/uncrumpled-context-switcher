#!/bin/bash
#
# Uncrumpled Context Switcher - Linux Installation Script
#
# This script installs the daemon and CLI tools to the user's local directories.
# It follows XDG Base Directory Specification for configuration.
#
# Usage:
#   ./install.sh [OPTIONS]
#
# Options:
#   --user       Install to user directories (default)
#   --system     Install system-wide (requires root)
#   --update     Update binaries only (preserve config, restart service)
#   --dev        Development mode (build + update binaries, no service restart)
#   --uninstall  Remove installed files
#   --help       Show this help message
#

set -e

# Default installation mode
INSTALL_MODE="user"
UPDATE_ONLY=false
DEV_MODE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --user)
            INSTALL_MODE="user"
            shift
            ;;
        --system)
            INSTALL_MODE="system"
            shift
            ;;
        --update)
            UPDATE_ONLY=true
            shift
            ;;
        --dev)
            DEV_MODE=true
            shift
            ;;
        --uninstall)
            INSTALL_MODE="uninstall"
            shift
            ;;
        --help|-h)
            echo "Uncrumpled Context Switcher - Linux Installation Script"
            echo ""
            echo "Usage: ./install.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --user       Install to user directories (default)"
            echo "  --system     Install system-wide (requires root)"
            echo "  --update     Update binaries only (preserve config, restart service)"
            echo "  --dev        Development mode (build + update binaries, no service restart)"
            echo "  --uninstall  Remove installed files"
            echo "  --help       Show this help message"
            echo ""
            echo "Examples:"
            echo "  ./install.sh              # Fresh install with interactive setup"
            echo "  ./install.sh --update     # Update binaries, preserve config, restart service"
            echo "  ./install.sh --dev        # Quick rebuild and update for development"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Set installation paths based on mode
if [[ "$INSTALL_MODE" == "system" ]]; then
    BIN_DIR="/usr/local/bin"
    CONFIG_DIR="/etc/uncrumpled-context-switcher"
    SERVICE_DIR="/etc/systemd/system"
    DATA_DIR="/var/lib/uncrumpled-context-switcher"
    SOCKET_UNIT_ENABLED=true
    SYSTEMCTL_CMD="systemctl"
else
    BIN_DIR="${HOME}/.local/bin"
    CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/uncrumpled-context-switcher"
    SERVICE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
    DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/uncrumpled-context-switcher"
    SOCKET_UNIT_ENABLED=false
    SYSTEMCTL_CMD="systemctl --user"
fi

# Source directory (where this script is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

echo "Uncrumpled Context Switcher Installer"
echo "======================================"
echo ""

# Uninstall mode
if [[ "$INSTALL_MODE" == "uninstall" ]]; then
    echo "Uninstalling Uncrumpled Context Switcher..."
    echo ""

    # Stop and disable services
    if [[ -d "$SERVICE_DIR" ]]; then
        if $SYSTEMCTL_CMD is-active uncrumpled-context-switcher.service &>/dev/null 2>&1; then
            echo "Stopping service..."
            $SYSTEMCTL_CMD stop uncrumpled-context-switcher.service 2>/dev/null || true
        fi
        if $SYSTEMCTL_CMD is-enabled uncrumpled-context-switcher.service &>/dev/null 2>&1; then
            echo "Disabling service..."
            $SYSTEMCTL_CMD disable uncrumpled-context-switcher.service 2>/dev/null || true
        fi
    fi

    # Remove binaries
    echo "Removing binaries..."
    rm -f "${BIN_DIR}/uncrumpled-context-switcher-daemon"
    rm -f "${BIN_DIR}/uncrumpled-context-switcher-cli"
    rm -f "${BIN_DIR}/uncrumpled-context-switcher"

    # Remove service files
    echo "Removing service files..."
    rm -f "${SERVICE_DIR}/uncrumpled-context-switcher.service"
    rm -f "${SERVICE_DIR}/uncrumpled-context-switcher.socket"
    rm -f "${SERVICE_DIR}/uncrumpled-context-switcher-socket.service"

    # Reload systemd
    if command -v systemctl &>/dev/null; then
        $SYSTEMCTL_CMD daemon-reload 2>/dev/null || true
    fi

    echo ""
    echo "Uninstallation complete!"
    echo ""
    echo "Note: Configuration files in ${CONFIG_DIR} were preserved."
    echo "To remove them manually: rm -rf ${CONFIG_DIR}"
    exit 0
fi

# Development mode: build first
if [[ "$DEV_MODE" == true ]]; then
    echo "Development mode: Building project..."
    echo ""

    if ! command -v jai &>/dev/null; then
        echo "Error: 'jai' compiler not found in PATH"
        exit 1
    fi

    pushd "$PROJECT_ROOT" > /dev/null
    if ! jai build.jai 2>&1; then
        echo "Error: Build failed"
        popd > /dev/null
        exit 1
    fi
    popd > /dev/null
    echo ""
    echo "Build successful!"
    echo ""

    # Dev mode implies update-only behavior
    UPDATE_ONLY=true
fi

# Check for built binaries
DAEMON_BIN="${PROJECT_ROOT}/bin/uncrumpled-context-switcher"
CLI_BIN="${PROJECT_ROOT}/build/uncrumpled-context-switcher-cli"

# Also check old build locations
if [[ ! -f "$DAEMON_BIN" ]]; then
    DAEMON_BIN="${PROJECT_ROOT}/build/uncrumpled-context-switcher-daemon"
fi

if [[ ! -f "$DAEMON_BIN" ]]; then
    echo "Error: Binary not found"
    echo ""
    echo "Searched locations:"
    echo "  ${PROJECT_ROOT}/bin/uncrumpled-context-switcher"
    echo "  ${PROJECT_ROOT}/build/uncrumpled-context-switcher-daemon"
    echo ""
    echo "Please build the project first:"
    echo "  cd ${PROJECT_ROOT}"
    echo "  jai build.jai"
    echo ""
    echo "Or use --dev mode to build and install in one step:"
    echo "  ./install.sh --dev"
    exit 1
fi

# Check if this is an update of existing installation
EXISTING_INSTALL=false
if [[ -f "${BIN_DIR}/uncrumpled-context-switcher-daemon" ]] || [[ -f "${BIN_DIR}/uncrumpled-context-switcher" ]]; then
    EXISTING_INSTALL=true
fi

# If update mode, verify existing installation
if [[ "$UPDATE_ONLY" == true ]] && [[ "$EXISTING_INSTALL" == false ]]; then
    echo "Error: --update specified but no existing installation found"
    echo ""
    echo "Run without --update for fresh installation:"
    echo "  ./install.sh"
    exit 1
fi

echo "Installation Mode: ${INSTALL_MODE}"
if [[ "$UPDATE_ONLY" == true ]]; then
    echo "Update Mode: Binaries only (preserving configuration)"
fi
if [[ "$DEV_MODE" == true ]]; then
    echo "Dev Mode: No service restart"
fi
echo "Binary Directory: ${BIN_DIR}"
echo "Config Directory: ${CONFIG_DIR}"
echo ""

# Stop running service before update (unless dev mode)
SERVICE_WAS_RUNNING=false
if [[ "$UPDATE_ONLY" == true ]] || [[ "$EXISTING_INSTALL" == true ]]; then
    if $SYSTEMCTL_CMD is-active uncrumpled-context-switcher.service &>/dev/null 2>&1; then
        SERVICE_WAS_RUNNING=true
        if [[ "$DEV_MODE" != true ]]; then
            echo "Stopping running service..."
            $SYSTEMCTL_CMD stop uncrumpled-context-switcher.service 2>/dev/null || true
            sleep 1
        fi
    fi
fi

# Skip interactive prompts in update mode
if [[ "$UPDATE_ONLY" != true ]]; then
    # Hotkey selection (only for fresh install)
    echo "Select a global hotkey to toggle the Context Switcher UI:"
    echo ""
    echo "  1) Ctrl+Alt+P          (default, recommended)"
    echo "  2) Ctrl+Shift+Space"
    echo "  3) Super+P             (Windows/Command key + P)"
    echo "  4) F12"
    echo "  5) None                (disable hotkey)"
    echo "  6) Custom              (configure manually in config.toml)"
    echo ""
    read -p "Enter your choice [1-6] (default: 1): " hotkey_choice

    # Set hotkey configuration based on choice
    case "${hotkey_choice:-1}" in
        1)
            HOTKEY_ENABLED="true"
            HOTKEY_KEY="P"
            HOTKEY_MODIFIERS="Ctrl+Alt"
            echo "Selected: Ctrl+Alt+P"
            ;;
        2)
            HOTKEY_ENABLED="true"
            HOTKEY_KEY="Space"
            HOTKEY_MODIFIERS="Ctrl+Shift"
            echo "Selected: Ctrl+Shift+Space"
            ;;
        3)
            HOTKEY_ENABLED="true"
            HOTKEY_KEY="P"
            HOTKEY_MODIFIERS="Super"
            echo "Selected: Super+P"
            ;;
        4)
            HOTKEY_ENABLED="true"
            HOTKEY_KEY="F12"
            HOTKEY_MODIFIERS=""
            echo "Selected: F12"
            ;;
        5)
            HOTKEY_ENABLED="false"
            HOTKEY_KEY=""
            HOTKEY_MODIFIERS=""
            echo "Selected: None (hotkey disabled)"
            ;;
        6)
            HOTKEY_ENABLED="true"
            HOTKEY_KEY=""
            HOTKEY_MODIFIERS=""
            echo "Selected: Custom (edit config.toml to set your hotkey)"
            ;;
        *)
            HOTKEY_ENABLED="true"
            HOTKEY_KEY="P"
            HOTKEY_MODIFIERS="Ctrl+Alt"
            echo "Invalid choice, using default: Ctrl+Alt+P"
            ;;
    esac
    echo ""
fi

# Create directories
echo "Creating directories..."
mkdir -p "$BIN_DIR"
mkdir -p "$CONFIG_DIR"
mkdir -p "$DATA_DIR"
if [[ "$UPDATE_ONLY" != true ]]; then
    mkdir -p "$SERVICE_DIR"
fi

# Install binaries
echo "Installing binaries..."
install -m 755 "$DAEMON_BIN" "${BIN_DIR}/uncrumpled-context-switcher"
# Also create symlink with old name for backwards compatibility
ln -sf "${BIN_DIR}/uncrumpled-context-switcher" "${BIN_DIR}/uncrumpled-context-switcher-daemon" 2>/dev/null || true
if [[ -f "$CLI_BIN" ]]; then
    install -m 755 "$CLI_BIN" "${BIN_DIR}/uncrumpled-context-switcher-cli"
fi

# Skip config and service file installation in update mode
if [[ "$UPDATE_ONLY" != true ]]; then
    # Install default configuration (if not exists)
    if [[ ! -f "${CONFIG_DIR}/config.toml" ]]; then
        echo "Creating default configuration..."
        cat > "${CONFIG_DIR}/config.toml" << EOF
# Uncrumpled Context Switcher Configuration
#
# This file defines context validation rules and daemon settings.
# See documentation for full configuration options.

[context]
# Allowed project patterns (regex)
allowed_projects = [".*"]

# Allowed profiles
allowed_profiles = ["default", "work", "personal", "gaming"]

# Allowed environments
allowed_environments = ["dev", "staging", "prod", "local"]

[tags]
# Tag definitions with conflict rules
[[tags.definitions]]
name = "--work"
description = "Work context"
conflicts_with = ["--personal", "--gaming"]

[[tags.definitions]]
name = "--personal"
description = "Personal context"
conflicts_with = ["--work"]

[[tags.definitions]]
name = "--gaming"
description = "Gaming context"
conflicts_with = ["--work"]

[params]
# Parameter definitions with type validation
[[params.definitions]]
name = "mode"
type = "enum"
values = ["debug", "release", "profile"]
default = "release"

[[params.definitions]]
name = "verbose"
type = "bool"
default = false

[daemon]
# Socket path (defaults to XDG_RUNTIME_DIR/uncrumpled-context-switcher/uncrumpled-context-switcher.sock)
# socket_path = "/tmp/uncrumpled-context-switcher.sock"

# Heartbeat interval in seconds
heartbeat_interval_seconds = 30

# Subscriber timeout in seconds
subscriber_timeout_seconds = 90

# Maximum execution log entries to keep
max_log_entries = 1000

# Log level: debug, info, warn, error
log_level = "info"

[hotkey]
# Global hotkey to toggle the Context Switcher UI
enabled = ${HOTKEY_ENABLED}
key = "${HOTKEY_KEY}"
modifiers = "${HOTKEY_MODIFIERS}"
EOF
    else
        echo "Preserving existing configuration..."
    fi

    # Install systemd service files
    echo "Installing systemd service files..."
    install -m 644 "${SCRIPT_DIR}/uncrumpled-context-switcher.service" "${SERVICE_DIR}/uncrumpled-context-switcher.service"
    install -m 644 "${SCRIPT_DIR}/uncrumpled-context-switcher.socket" "${SERVICE_DIR}/uncrumpled-context-switcher.socket"
    install -m 644 "${SCRIPT_DIR}/uncrumpled-context-switcher-socket.service" "${SERVICE_DIR}/uncrumpled-context-switcher-socket.service"

    # Update service file with correct binary path
    sed -i "s|%h/.local/bin/uncrumpled-context-switcher-daemon|${BIN_DIR}/uncrumpled-context-switcher|g" "${SERVICE_DIR}/uncrumpled-context-switcher.service"
    sed -i "s|%h/.local/bin/uncrumpled-context-switcher-daemon|${BIN_DIR}/uncrumpled-context-switcher|g" "${SERVICE_DIR}/uncrumpled-context-switcher-socket.service"

    # Reload systemd
    echo "Reloading systemd..."
    if command -v systemctl &>/dev/null; then
        $SYSTEMCTL_CMD daemon-reload 2>/dev/null || true
    fi
fi

# Restart service if it was running (unless dev mode)
if [[ "$SERVICE_WAS_RUNNING" == true ]] && [[ "$DEV_MODE" != true ]]; then
    echo "Restarting service..."
    $SYSTEMCTL_CMD start uncrumpled-context-switcher.service 2>/dev/null || true
fi

echo ""
echo "Installation complete!"
echo ""

if [[ "$UPDATE_ONLY" == true ]]; then
    if [[ "$DEV_MODE" == true ]]; then
        echo "Binaries updated. Service was not restarted (dev mode)."
        echo ""
        echo "To manually restart:"
        echo "  $SYSTEMCTL_CMD restart uncrumpled-context-switcher"
    else
        if [[ "$SERVICE_WAS_RUNNING" == true ]]; then
            echo "Binaries updated and service restarted."
        else
            echo "Binaries updated. Service was not running."
        fi
    fi
else
    echo "Next steps:"
    echo ""

    if [[ "$INSTALL_MODE" == "user" ]]; then
        echo "1. Add ${BIN_DIR} to your PATH (if not already):"
        echo "   export PATH=\"\$PATH:${BIN_DIR}\""
        echo ""
        echo "2. Enable and start the service:"
        echo "   systemctl --user enable uncrumpled-context-switcher"
        echo "   systemctl --user start uncrumpled-context-switcher"
        echo ""
        echo "3. Check the status:"
        echo "   systemctl --user status uncrumpled-context-switcher"
        echo ""
        echo "4. View logs:"
        echo "   journalctl --user -u uncrumpled-context-switcher -f"
    else
        echo "1. Enable and start the service:"
        echo "   sudo systemctl enable uncrumpled-context-switcher"
        echo "   sudo systemctl start uncrumpled-context-switcher"
        echo ""
        echo "2. Check the status:"
        echo "   sudo systemctl status uncrumpled-context-switcher"
    fi
fi

echo ""
echo "Configuration file: ${CONFIG_DIR}/config.toml"
echo ""
