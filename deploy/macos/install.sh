#!/bin/bash
#
# Uncrumpled Context Switcher - macOS Installation Script
#
# This script installs the daemon and CLI tools to the user's local directories.
# It follows macOS conventions for application data storage.
#
# Usage:
#   ./install.sh [OPTIONS]
#
# Options:
#   --user         Install to user directories (default)
#   --socket       Use socket-activated service (starts on first connection)
#   --uninstall    Remove installed files
#   --help         Show this help message
#

set -e

# Default installation mode
INSTALL_MODE="user"
USE_SOCKET_ACTIVATION="false"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --user)
            INSTALL_MODE="user"
            shift
            ;;
        --socket)
            USE_SOCKET_ACTIVATION="true"
            shift
            ;;
        --uninstall)
            INSTALL_MODE="uninstall"
            shift
            ;;
        --help|-h)
            echo "Uncrumpled Context Switcher - macOS Installation Script"
            echo ""
            echo "Usage: ./install.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --user         Install to user directories (default)"
            echo "  --socket       Use socket-activated service (starts on first connection)"
            echo "  --uninstall    Remove installed files"
            echo "  --help         Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Set installation paths
BIN_DIR="${HOME}/.local/bin"
APP_SUPPORT_DIR="${HOME}/Library/Application Support/uncrumpled-context-switcher"
LAUNCH_AGENTS_DIR="${HOME}/Library/LaunchAgents"
LOGS_DIR="${HOME}/Library/Logs/uncrumpled-context-switcher"
CACHE_DIR="${HOME}/Library/Caches/uncrumpled-context-switcher"

# Socket path (use TMPDIR if available, otherwise /tmp)
if [[ -n "$TMPDIR" ]]; then
    SOCKET_PATH="${TMPDIR}uncrumpled-context-switcher.sock"
else
    SOCKET_PATH="/tmp/uncrumpled-context-switcher.sock"
fi

# Service label
SERVICE_LABEL="com.uncrumpled-context-switcher.daemon"
SOCKET_SERVICE_LABEL="com.uncrumpled-context-switcher.daemon.socket"

# Source directory (where this script is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

echo "Uncrumpled Context Switcher Installer (macOS)"
echo "=============================================="
echo ""

# Uninstall mode
if [[ "$INSTALL_MODE" == "uninstall" ]]; then
    echo "Uninstalling Uncrumpled Context Switcher..."
    echo ""

    # Unload launchd services
    echo "Unloading launchd services..."
    if launchctl list "$SERVICE_LABEL" &>/dev/null 2>&1; then
        launchctl unload "${LAUNCH_AGENTS_DIR}/${SERVICE_LABEL}.plist" 2>/dev/null || true
    fi
    if launchctl list "$SOCKET_SERVICE_LABEL" &>/dev/null 2>&1; then
        launchctl unload "${LAUNCH_AGENTS_DIR}/${SOCKET_SERVICE_LABEL}.plist" 2>/dev/null || true
    fi

    # Remove binaries
    echo "Removing binaries..."
    rm -f "${BIN_DIR}/uncrumpled-context-switcher-daemon"
    rm -f "${BIN_DIR}/uncrumpled-context-switcher-cli"

    # Remove launchd plist files
    echo "Removing launchd plist files..."
    rm -f "${LAUNCH_AGENTS_DIR}/${SERVICE_LABEL}.plist"
    rm -f "${LAUNCH_AGENTS_DIR}/${SOCKET_SERVICE_LABEL}.plist"

    # Remove socket file
    rm -f "$SOCKET_PATH"

    echo ""
    echo "Uninstallation complete!"
    echo ""
    echo "Note: Configuration files in ${APP_SUPPORT_DIR} were preserved."
    echo "To remove them manually: rm -rf \"${APP_SUPPORT_DIR}\""
    echo ""
    echo "Log files in ${LOGS_DIR} were also preserved."
    echo "To remove them: rm -rf \"${LOGS_DIR}\""
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
echo "Config Directory: ${APP_SUPPORT_DIR}"
echo "LaunchAgents Directory: ${LAUNCH_AGENTS_DIR}"
echo "Socket Path: ${SOCKET_PATH}"
if [[ "$USE_SOCKET_ACTIVATION" == "true" ]]; then
    echo "Socket Activation: Enabled"
fi
echo ""

# Create directories
echo "Creating directories..."
mkdir -p "$BIN_DIR"
mkdir -p "$APP_SUPPORT_DIR"
mkdir -p "$LAUNCH_AGENTS_DIR"
mkdir -p "$LOGS_DIR"
mkdir -p "$CACHE_DIR"

# Install binaries
echo "Installing binaries..."
install -m 755 "$DAEMON_BIN" "${BIN_DIR}/uncrumpled-context-switcher-daemon"
if [[ -f "$CLI_BIN" ]]; then
    install -m 755 "$CLI_BIN" "${BIN_DIR}/uncrumpled-context-switcher-cli"
fi

# Install default configuration (if not exists)
if [[ ! -f "${APP_SUPPORT_DIR}/config.toml" ]]; then
    echo "Creating default configuration..."
    cat > "${APP_SUPPORT_DIR}/config.toml" << 'EOF'
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
# Socket path (defaults to $TMPDIR/uncrumpled-context-switcher.sock)
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

# Install launchd plist file
echo "Installing launchd plist..."

# Get TMPDIR for plist
TMPDIR_VALUE="${TMPDIR:-/tmp}"
# Remove trailing slash if present
TMPDIR_VALUE="${TMPDIR_VALUE%/}"

if [[ "$USE_SOCKET_ACTIVATION" == "true" ]]; then
    PLIST_SRC="${SCRIPT_DIR}/com.uncrumpled-context-switcher.daemon.socket.plist"
    PLIST_DST="${LAUNCH_AGENTS_DIR}/${SOCKET_SERVICE_LABEL}.plist"
    ACTIVE_LABEL="$SOCKET_SERVICE_LABEL"

    # Update placeholders in socket-activated plist
    sed -e "s|__INSTALL_DIR__|${BIN_DIR}|g" \
        -e "s|__HOME_DIR__|${HOME}|g" \
        -e "s|__TMPDIR__|${TMPDIR_VALUE}|g" \
        -e "s|__SOCKET_PATH__|${SOCKET_PATH}|g" \
        "$PLIST_SRC" > "$PLIST_DST"
else
    PLIST_SRC="${SCRIPT_DIR}/com.uncrumpled-context-switcher.daemon.plist"
    PLIST_DST="${LAUNCH_AGENTS_DIR}/${SERVICE_LABEL}.plist"
    ACTIVE_LABEL="$SERVICE_LABEL"

    # Update placeholders in standard plist
    sed -e "s|__INSTALL_DIR__|${BIN_DIR}|g" \
        -e "s|__HOME_DIR__|${HOME}|g" \
        -e "s|__TMPDIR__|${TMPDIR_VALUE}|g" \
        "$PLIST_SRC" > "$PLIST_DST"
fi

# Set proper permissions on plist
chmod 644 "$PLIST_DST"

# Unload any existing service
if launchctl list "$SERVICE_LABEL" &>/dev/null 2>&1; then
    echo "Unloading existing service..."
    launchctl unload "${LAUNCH_AGENTS_DIR}/${SERVICE_LABEL}.plist" 2>/dev/null || true
fi
if launchctl list "$SOCKET_SERVICE_LABEL" &>/dev/null 2>&1; then
    launchctl unload "${LAUNCH_AGENTS_DIR}/${SOCKET_SERVICE_LABEL}.plist" 2>/dev/null || true
fi

echo ""
echo "Installation complete!"
echo ""
echo "Next steps:"
echo ""
echo "1. Add ${BIN_DIR} to your PATH (if not already):"
echo "   Add this to your ~/.zshrc or ~/.bash_profile:"
echo "   export PATH=\"\$PATH:${BIN_DIR}\""
echo ""
echo "2. Load and start the service:"
echo "   launchctl load \"$PLIST_DST\""
echo ""
if [[ "$USE_SOCKET_ACTIVATION" == "true" ]]; then
    echo "   (Socket-activated: service starts on first connection)"
    echo ""
fi
echo "3. Check if the service is running:"
echo "   launchctl list | grep uncrumpled-context-switcher"
echo ""
echo "4. View logs:"
echo "   tail -f \"${LOGS_DIR}/daemon.log\""
echo ""
echo "5. Stop the service:"
echo "   launchctl unload \"$PLIST_DST\""
echo ""
echo "Configuration file: ${APP_SUPPORT_DIR}/config.toml"
echo ""
