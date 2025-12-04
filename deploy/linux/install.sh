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
    CONFIG_DIR="/etc/uncrumpled"
    SERVICE_DIR="/etc/systemd/system"
    DATA_DIR="/var/lib/uncrumpled"
    SOCKET_UNIT_ENABLED=true
else
    BIN_DIR="${HOME}/.local/bin"
    CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/uncrumpled"
    SERVICE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
    DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/uncrumpled"
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
        if systemctl --user is-active uncrumpled.service &>/dev/null 2>&1; then
            echo "Stopping service..."
            systemctl --user stop uncrumpled.service 2>/dev/null || true
        fi
        if systemctl --user is-enabled uncrumpled.service &>/dev/null 2>&1; then
            echo "Disabling service..."
            systemctl --user disable uncrumpled.service 2>/dev/null || true
        fi
    fi

    # Remove binaries
    echo "Removing binaries..."
    rm -f "${BIN_DIR}/uncrumpled-daemon"
    rm -f "${BIN_DIR}/uncrumpled"

    # Remove service files
    echo "Removing service files..."
    rm -f "${SERVICE_DIR}/uncrumpled.service"
    rm -f "${SERVICE_DIR}/uncrumpled.socket"
    rm -f "${SERVICE_DIR}/uncrumpled-socket.service"

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
DAEMON_BIN="${PROJECT_ROOT}/build/uncrumpled-daemon"
CLI_BIN="${PROJECT_ROOT}/build/uncrumpled"

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
install -m 755 "$DAEMON_BIN" "${BIN_DIR}/uncrumpled-daemon"
if [[ -f "$CLI_BIN" ]]; then
    install -m 755 "$CLI_BIN" "${BIN_DIR}/uncrumpled"
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
# Socket path (defaults to XDG_RUNTIME_DIR/uncrumpled/uncrumpled.sock)
# socket_path = "/tmp/uncrumpled.sock"

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
install -m 644 "${SCRIPT_DIR}/uncrumpled.service" "${SERVICE_DIR}/uncrumpled.service"
install -m 644 "${SCRIPT_DIR}/uncrumpled.socket" "${SERVICE_DIR}/uncrumpled.socket"
install -m 644 "${SCRIPT_DIR}/uncrumpled-socket.service" "${SERVICE_DIR}/uncrumpled-socket.service"

# Update service file with correct binary path
sed -i "s|%h/.local/bin/uncrumpled-daemon|${BIN_DIR}/uncrumpled-daemon|g" "${SERVICE_DIR}/uncrumpled.service"
sed -i "s|%h/.local/bin/uncrumpled-daemon|${BIN_DIR}/uncrumpled-daemon|g" "${SERVICE_DIR}/uncrumpled-socket.service"

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
    echo "   systemctl --user enable uncrumpled"
    echo "   systemctl --user start uncrumpled"
    echo ""
    echo "3. Check the status:"
    echo "   systemctl --user status uncrumpled"
    echo ""
    echo "4. View logs:"
    echo "   journalctl --user -u uncrumpled -f"
else
    echo "1. Enable and start the service:"
    echo "   sudo systemctl enable uncrumpled"
    echo "   sudo systemctl start uncrumpled"
    echo ""
    echo "2. Check the status:"
    echo "   sudo systemctl status uncrumpled"
fi

echo ""
echo "Configuration file: ${CONFIG_DIR}/config.toml"
echo ""
