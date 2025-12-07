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
#   --update       Update binaries only (preserve config, restart service)
#   --dev          Development mode (build + update binaries, no service restart)
#   --uninstall    Remove installed files
#   --help         Show this help message
#

set -e

# Default installation mode
INSTALL_MODE="user"
USE_SOCKET_ACTIVATION="false"
UPDATE_ONLY=false
DEV_MODE=false

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
            echo "Uncrumpled Context Switcher - macOS Installation Script"
            echo ""
            echo "Usage: ./install.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --user         Install to user directories (default)"
            echo "  --socket       Use socket-activated service (starts on first connection)"
            echo "  --update       Update binaries only (preserve config, restart service)"
            echo "  --dev          Development mode (build + update binaries, no service restart)"
            echo "  --uninstall    Remove installed files"
            echo "  --help         Show this help message"
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
    rm -f "${BIN_DIR}/uncrumpled-context-switcher"

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
echo "Config Directory: ${APP_SUPPORT_DIR}"
echo "Socket Path: ${SOCKET_PATH}"
if [[ "$USE_SOCKET_ACTIVATION" == "true" ]]; then
    echo "Socket Activation: Enabled"
fi
echo ""

# Stop running service before update (unless dev mode)
SERVICE_WAS_RUNNING=false
if [[ "$UPDATE_ONLY" == true ]] || [[ "$EXISTING_INSTALL" == true ]]; then
    if launchctl list "$SERVICE_LABEL" &>/dev/null 2>&1; then
        SERVICE_WAS_RUNNING=true
        ACTIVE_LABEL="$SERVICE_LABEL"
        PLIST_DST="${LAUNCH_AGENTS_DIR}/${SERVICE_LABEL}.plist"
        if [[ "$DEV_MODE" != true ]]; then
            echo "Stopping running service..."
            launchctl unload "$PLIST_DST" 2>/dev/null || true
            sleep 1
        fi
    elif launchctl list "$SOCKET_SERVICE_LABEL" &>/dev/null 2>&1; then
        SERVICE_WAS_RUNNING=true
        ACTIVE_LABEL="$SOCKET_SERVICE_LABEL"
        PLIST_DST="${LAUNCH_AGENTS_DIR}/${SOCKET_SERVICE_LABEL}.plist"
        if [[ "$DEV_MODE" != true ]]; then
            echo "Stopping running service..."
            launchctl unload "$PLIST_DST" 2>/dev/null || true
            sleep 1
        fi
    fi
fi

# Skip interactive prompts in update mode
if [[ "$UPDATE_ONLY" != true ]]; then
    # Hotkey selection
    echo "Select a global hotkey to toggle the Context Switcher UI:"
    echo ""
    echo "  1) Ctrl+Alt+P          (default, recommended)"
    echo "  2) Ctrl+Shift+Space"
    echo "  3) Command+P           (macOS Command key + P)"
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
            HOTKEY_MODIFIERS="Command"
            echo "Selected: Command+P"
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
mkdir -p "$APP_SUPPORT_DIR"
mkdir -p "$LOGS_DIR"
mkdir -p "$CACHE_DIR"
if [[ "$UPDATE_ONLY" != true ]]; then
    mkdir -p "$LAUNCH_AGENTS_DIR"
fi

# Install binaries
echo "Installing binaries..."
install -m 755 "$DAEMON_BIN" "${BIN_DIR}/uncrumpled-context-switcher"
# Also create symlink with old name for backwards compatibility
ln -sf "${BIN_DIR}/uncrumpled-context-switcher" "${BIN_DIR}/uncrumpled-context-switcher-daemon" 2>/dev/null || true
if [[ -f "$CLI_BIN" ]]; then
    install -m 755 "$CLI_BIN" "${BIN_DIR}/uncrumpled-context-switcher-cli"
fi

# Skip config and plist installation in update mode
if [[ "$UPDATE_ONLY" != true ]]; then
    # Install default configuration (if not exists)
    if [[ ! -f "${APP_SUPPORT_DIR}/config.toml" ]]; then
        echo "Creating default configuration..."
        cat > "${APP_SUPPORT_DIR}/config.toml" << EOF
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
# Socket path (defaults to \$TMPDIR/uncrumpled-context-switcher.sock)
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
fi

# Restart service if it was running (unless dev mode)
if [[ "$SERVICE_WAS_RUNNING" == true ]] && [[ "$DEV_MODE" != true ]]; then
    echo "Restarting service..."
    launchctl load "$PLIST_DST" 2>/dev/null || true
fi

echo ""
echo "Installation complete!"
echo ""

if [[ "$UPDATE_ONLY" == true ]]; then
    if [[ "$DEV_MODE" == true ]]; then
        echo "Binaries updated. Service was not restarted (dev mode)."
        echo ""
        echo "To manually restart:"
        if [[ -n "$PLIST_DST" ]]; then
            echo "  launchctl unload \"$PLIST_DST\""
            echo "  launchctl load \"$PLIST_DST\""
        else
            echo "  launchctl unload ~/Library/LaunchAgents/com.uncrumpled-context-switcher.daemon.plist"
            echo "  launchctl load ~/Library/LaunchAgents/com.uncrumpled-context-switcher.daemon.plist"
        fi
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
fi

echo ""
echo "Configuration file: ${APP_SUPPORT_DIR}/config.toml"
echo ""
