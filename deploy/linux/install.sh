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
#   --uninstall  Remove installed files
#   --help       Show this help message
#

set -e

# Default installation mode
INSTALL_MODE="user"

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
            echo "  --uninstall  Remove installed files"
            echo "  --help       Show this help message"
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
else
    BIN_DIR="${HOME}/.local/bin"
    CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/uncrumpled-context-switcher"
    SERVICE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
    DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/uncrumpled-context-switcher"
    SOCKET_UNIT_ENABLED=false
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
        if systemctl --user is-active uncrumpled-context-switcher.service &>/dev/null 2>&1; then
            echo "Stopping service..."
            systemctl --user stop uncrumpled-context-switcher.service 2>/dev/null || true
        fi
        if systemctl --user is-enabled uncrumpled-context-switcher.service &>/dev/null 2>&1; then
            echo "Disabling service..."
            systemctl --user disable uncrumpled-context-switcher.service 2>/dev/null || true
        fi
    fi

    # Remove binaries
    echo "Removing binaries..."
    rm -f "${BIN_DIR}/uncrumpled-context-switcher-daemon"
    rm -f "${BIN_DIR}/uncrumpled-context-switcher-cli"

    # Remove service files
    echo "Removing service files..."
    rm -f "${SERVICE_DIR}/uncrumpled-context-switcher.service"
    rm -f "${SERVICE_DIR}/uncrumpled-context-switcher.socket"
    rm -f "${SERVICE_DIR}/uncrumpled-context-switcher-socket.service"

    # Reload systemd
    if command -v systemctl &>/dev/null; then
        systemctl --user daemon-reload 2>/dev/null || true
    fi

    echo ""
    echo "Uninstallation complete!"
    echo ""
    echo "Note: Configuration files in ${CONFIG_DIR} were preserved."
    echo "To remove them manually: rm -rf ${CONFIG_DIR}"
    exit 0
fi

# Check for built binaries
DAEMON_BIN="${PROJECT_ROOT}/build/uncrumpled-context-switcher-daemon"
CLI_BIN="${PROJECT_ROOT}/build/uncrumpled-context-switcher-cli"

if [[ ! -f "$DAEMON_BIN" ]]; then
    echo "Error: Daemon binary not found at ${DAEMON_BIN}"
    echo ""
    echo "Please build the project first:"
    echo "  cd ${PROJECT_ROOT}"
    echo "  jai build_daemon.jai"
    exit 1
fi

echo "Installation Mode: ${INSTALL_MODE}"
echo "Binary Directory: ${BIN_DIR}"
echo "Config Directory: ${CONFIG_DIR}"
echo "Service Directory: ${SERVICE_DIR}"
echo ""

# Create directories
echo "Creating directories..."
mkdir -p "$BIN_DIR"
mkdir -p "$CONFIG_DIR"
mkdir -p "$SERVICE_DIR"
mkdir -p "$DATA_DIR"

# Install binaries
echo "Installing binaries..."
install -m 755 "$DAEMON_BIN" "${BIN_DIR}/uncrumpled-context-switcher-daemon"
if [[ -f "$CLI_BIN" ]]; then
    install -m 755 "$CLI_BIN" "${BIN_DIR}/uncrumpled-context-switcher-cli"
fi

# Install default configuration (if not exists)
if [[ ! -f "${CONFIG_DIR}/config.toml" ]]; then
    echo "Creating default configuration..."
    cat > "${CONFIG_DIR}/config.toml" << 'EOF'
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
EOF
fi

# Install systemd service files
echo "Installing systemd service files..."
install -m 644 "${SCRIPT_DIR}/uncrumpled-context-switcher.service" "${SERVICE_DIR}/uncrumpled-context-switcher.service"
install -m 644 "${SCRIPT_DIR}/uncrumpled-context-switcher.socket" "${SERVICE_DIR}/uncrumpled-context-switcher.socket"
install -m 644 "${SCRIPT_DIR}/uncrumpled-context-switcher-socket.service" "${SERVICE_DIR}/uncrumpled-context-switcher-socket.service"

# Update service file with correct binary path
sed -i "s|%h/.local/bin/uncrumpled-context-switcher-daemon|${BIN_DIR}/uncrumpled-context-switcher-daemon|g" "${SERVICE_DIR}/uncrumpled-context-switcher.service"
sed -i "s|%h/.local/bin/uncrumpled-context-switcher-daemon|${BIN_DIR}/uncrumpled-context-switcher-daemon|g" "${SERVICE_DIR}/uncrumpled-context-switcher-socket.service"

# Reload systemd
echo "Reloading systemd..."
if command -v systemctl &>/dev/null; then
    if [[ "$INSTALL_MODE" == "system" ]]; then
        systemctl daemon-reload
    else
        systemctl --user daemon-reload
    fi
fi

echo ""
echo "Installation complete!"
echo ""
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

echo ""
echo "Configuration file: ${CONFIG_DIR}/config.toml"
echo ""
