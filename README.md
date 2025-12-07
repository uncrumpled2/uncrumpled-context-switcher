# Uncrumpled Context Switcher

```
                                                         _ 
  _   _ _ __   ___ _ __ _   _ _ __ ___  _ __ | | ___  __| |
 | | | | '_ \ / __| '__| | | | '_ ` _ \| '_ \| |/ _ \/ _` |
 | |_| | | | | (__| |  | |_| | | | | | | |_) | |  __/ (_| |
  \__,_|_| |_|\___|_|   \__,_|_| |_| |_| .__/|_|\___|\__,_|
                  _            _       |_|
   ___ ___  _ __ | |_ _____  _| |_
  / __/ _ \| '_ \| __/ _ \ \/ / __|
 | (_| (_) | | | | ||  __/>  <| |_
  \___\___/|_| |_|\__\___/_/\_\\__|
              _ _       _
 _____      _(_) |_ ___| |__   ___ _ __
/ __\ \ /\ / / | __/ __| '_ \ / _ \ '__|
\__ \\ V  V /| | || (__| | | |  __/ |
|___/ \_/\_/ |_|\__\___|_| |_|\___|_|
```

A cross-platform background daemon for managing development context state, enabling seamless coordination between tools, editors, and services.

## Overview

**Uncrumpled Context Switcher** is a local IPC daemon that maintains your current development context (project, profile, environment, tags, and custom parameters) and broadcasts context changes to subscribed services. Think of it as a "context bus" that keeps all your tools in sync.

**Language:** Jai
**Platforms:** Linux, macOS, Windows
**Protocol:** JSON-RPC 2.0 over Unix Domain Sockets (Linux/macOS) or Named Pipes (Windows)

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     UNCRUMPLED CONTEXT SWITCHER                         │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │                     CONTEXT STATE STORE                          │   │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌───────────────────────┐   │   │
│  │  │Project  │ │Profile  │ │  Env    │ │  Tags & User Params   │   │   │
│  │  │   ID    │ │         │ │         │ │  (--work, --uni, etc) │   │   │
│  │  └─────────┘ └─────────┘ └─────────┘ └───────────────────────┘   │   │
│  │  ┌───────────────────────────────────────────────────────────┐   │   │
│  │  │              Workspace Metadata                           │   │   │
│  │  └───────────────────────────────────────────────────────────┘   │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │                      IPC LAYER                                   │   │
│  │  ┌────────────────────┐  ┌────────────────────────────────────┐  │   │
│  │  │ Unix Domain Socket │  │ Windows Named Pipe                 │  │   │
│  │  │ (Linux/macOS)      │  │ \\.\pipe\uncrumpled-context        │  │   │
│  │  └────────────────────┘  └────────────────────────────────────┘  │   │
│  │                              │                                   │   │
│  │                    ┌─────────▼─────────┐                         │   │
│  │                    │  JSON-RPC Server  │                         │   │
│  │                    │  (Protocol v1.x)  │                         │   │
│  │                    └───────────────────┘                         │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │                 SUBSCRIPTION MANAGER                             │   │
│  │  ┌─────────────────────────────────────────────────────────┐     │   │
│  │  │ Registered Subscribers                                  │     │   │
│  │  │  - endpoint: socket/pipe path                           │     │   │
│  │  │  - capabilities: [context.change, tags.update, ...]     │     │   │
│  │  │  - heartbeat: last_ack timestamp                        │     │   │
│  │  └─────────────────────────────────────────────────────────┘     │   │
│  │  ┌─────────────────────────────────────────────────────────┐     │   │
│  │  │ Event Dispatcher (push JSON events to subscribers)      │     │   │
│  │  └─────────────────────────────────────────────────────────┘     │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │                   PREVIEW ENGINE                                 │   │
│  │  - Query registered services for activation preview              │   │
│  │  - Execute preview callbacks                                     │   │
│  │  - Generate visual flow / textual summary                        │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │                   EXECUTION LOG SYSTEM                           │   │
│  │  - Step-by-step execution history (like CircleCI)                │   │
│  │  - Per-service logs with timestamps                              │   │
│  │  - Success/failure status per step                               │   │
│  │  - Debug inspection API                                          │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │                 CONFIGURATION SYSTEM                             │   │
│  │  - User config file (TOML) for allowed states/params             │   │
│  │  - Schema validation                                             │   │
│  │  - Context constraint checking                                   │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

## Features

- **Context State Management** - Track project, profile, environment, tags, and custom parameters
- **Service Registration** - Services register with capabilities and receive relevant events
- **Event Subscription** - Subscribe to specific events (e.g., `context.changed`, `context.*`)
- **Preview System** - Preview what will happen before applying context changes
- **Execution Logs** - Step-by-step logs of context change execution across services
- **Configuration Validation** - TOML-based config with profile/environment/tag constraints
- **Heartbeat Monitoring** - Automatic cleanup of stale subscribers and services
- **Cross-Platform** - Linux (systemd), macOS (launchd), Windows (named pipes + service)

## Building

### Prerequisites

1. **Jai Compiler** - Ensure `jai` is in your PATH
2. **SDL2** - Required for the UI component
3. **Skia** - Required for the UI component
4. **toml-c** - Included as a git submodule for config parsing

### Build Commands

```bash
# Initialize submodules (for toml-c)
git submodule update --init --recursive

# Build the toml-c library
cd modules/jai-toml-c && jai generate.jai && cd ../..

# Build the daemon
jai build_daemon.jai

# Build the CLI client
jai build_cli.jai

# Build the UI (optional)
jai build.jai

# Run tests
jai tests/run_tests.jai && LD_LIBRARY_PATH=$LD_LIBRARY_PATH:./modules/jai-toml-c/toml-c ./tests/run_tests
```

### Output Binaries

- `bin/uncrumpled-daemon` - The background daemon
- `bin/uncrumpled-cli` - Command-line client
- `bin/uncrumpled` - UI application (optional)

## Installation

### Linux (systemd)

```bash
# Install for current user
./deploy/linux/install.sh --user

# Or install system-wide
sudo ./deploy/linux/install.sh --system

# Enable and start
systemctl --user enable --now uncrumpled-context-switcher
systemctl --user start uncrumpled-context-switcher

systemctl --user status uncrumpled-context-switcher

journalctl --user -u uncrumpled-context-switcher -f
```

systemctl --user daemon-reload
systemctl --user restart uncrumpled-context-switcher

Note: i did this TODO: static build?
sudo cp /root/programming/repo/uncrumpled-context-switcher/modules/libskia.so /usr/local/lib/
sudo ldconfig

### macOS (launchd)

```bash
# Install for current user
./deploy/macos/install.sh --user

# Or with socket activation
./deploy/macos/install.sh --socket
```

### Windows

```powershell
# Install as user startup program
.\deploy\windows\install.ps1 -Startup

# Or install as Windows service
.\deploy\windows\install.ps1 -Service
```

## Usage

### Running the Daemon

```bash
# Run in foreground
uncrumpled-context-switcher daemon

# Run as daemon (background)
uncrumpled-context-switcher-daemon --daemon

# With custom socket path
uncrumpled-context-switcher-daemon --socket /tmp/my-context.sock

# With custom config
uncrumpled-context-switcher-daemon --config ~/.config/uncrumpled/custom.toml
```

### CLI Commands

```bash
# Get current context
uncrumpled-context-switcher-cli context get

# Add a tag
uncrumpled-context-switcher-cli context add-tag --work

# Remove a tag
uncrumpled-context-switcher-cli context remove-tag --work

# List registered services
uncrumpled-context-switcher-cli service list

# View execution logs
uncrumpled-context-switcher-cli logs list

# Ping daemon
uncrumpled-context-switcher-cli ping
```

## Configuration

Configuration file: `~/.config/uncrumpled/config.toml`

```toml
[context]
allowed_projects = [".*"]
allowed_profiles = ["default", "work", "personal", "gaming"]
allowed_environments = ["dev", "staging", "prod", "local"]

[tags]
[[tags.definitions]]
name = "--work"
description = "Work context"
conflicts_with = ["--personal", "--gaming"]

[[tags.definitions]]
name = "--personal"
description = "Personal context"

[[tags.definitions]]
name = "--gaming"
description = "Gaming context"

[params]
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
socket_path = "/tmp/uncrumpled.sock"
heartbeat_interval_seconds = 30
subscriber_timeout_seconds = 90
max_log_entries = 1000
log_level = "info"
```

## JSON-RPC API

All communication uses JSON-RPC 2.0 over the local socket/pipe.

### Context Operations

```json
{"jsonrpc": "2.0", "method": "context.get", "id": 1}
{"jsonrpc": "2.0", "method": "context.set", "params": {"project_id": "myproj", "profile": "work"}, "id": 2}
{"jsonrpc": "2.0", "method": "context.update", "params": {"tags": ["--work"]}, "id": 3}
{"jsonrpc": "2.0", "method": "context.addTag", "params": {"tag": "--work"}, "id": 4}
{"jsonrpc": "2.0", "method": "context.removeTag", "params": {"tag": "--work"}, "id": 5}
{"jsonrpc": "2.0", "method": "context.setParam", "params": {"key": "mode", "value": "debug"}, "id": 6}
{"jsonrpc": "2.0", "method": "context.getParam", "params": {"key": "mode"}, "id": 7}
```

### Service Registration

```json
{"jsonrpc": "2.0", "method": "service.register", "params": {
    "id": "my-service",
    "name": "My Service",
    "endpoint": "/tmp/my-service.sock",
    "capabilities": {
        "events": ["context.changed"],
        "provides_preview": true,
        "api_version": "1.0.0"
    }
}, "id": 8}
{"jsonrpc": "2.0", "method": "service.unregister", "params": {"id": "my-service"}, "id": 9}
{"jsonrpc": "2.0", "method": "service.list", "id": 10}
{"jsonrpc": "2.0", "method": "service.heartbeat", "params": {"id": "my-service"}, "id": 11}
```

### Event Subscription

```json
{"jsonrpc": "2.0", "method": "subscribe", "params": {
    "events": ["context.changed", "service.*"],
    "endpoint": "/tmp/my-client.sock"
}, "id": 12}
{"jsonrpc": "2.0", "method": "unsubscribe", "params": {"endpoint": "/tmp/my-client.sock"}, "id": 13}
```

### Preview

```json
{"jsonrpc": "2.0", "method": "preview.get", "params": {
    "proposed_context": {"project_id": "newproj", "tags": ["--work"]}
}, "id": 14}
{"jsonrpc": "2.0", "method": "preview.getVisual", "params": {
    "proposed_context": {"project_id": "newproj"},
    "format": "ansi"
}, "id": 15}
```

### Execution Logs

```json
{"jsonrpc": "2.0", "method": "logs.list", "params": {"limit": 50}, "id": 16}
{"jsonrpc": "2.0", "method": "logs.get", "params": {"id": "exec-123"}, "id": 17}
{"jsonrpc": "2.0", "method": "logs.byService", "params": {"service_id": "my-service", "limit": 20}, "id": 18}
```

### Handshake

```json
{"jsonrpc": "2.0", "method": "handshake", "params": {
    "client_version": "1.0.0",
    "capabilities": ["context", "subscribe", "preview"]
}, "id": 0}
```

### Push Notifications (Server → Client)

```json
{"jsonrpc": "2.0", "method": "notify.contextChanged", "params": {
    "previous": {"project_id": "old", "tags": []},
    "current": {"project_id": "new", "tags": ["--work"]},
    "changed_fields": ["project_id", "tags"],
    "version": 42
}}
```

## Service SDK

The SDK (`src/sdk/`) provides a high-level client for building services:

```jai
#import "uncrumpled_sdk";

main :: () {
    client: Service_Client;
    init_service_client(*client);
    defer deinit_service_client(*client);

    // Connect to daemon
    if !connect(*client) {
        print("Failed to connect to daemon\n");
        return;
    }

    // Register service
    reg := make_registration("my-service", "My Service", "/tmp/my.sock");
    register_service(*client, *reg);

    // Subscribe to events
    subscribe_to_events(*client, .["context.changed"]);

    // Start listener and handle events
    start_listener(*client);
    while running {
        if has_pending_events(*client) {
            event := receive_event(*client);
            // Handle event...
            free_sdk_event(*event);
        }
        send_heartbeat_if_needed(*client);
    }
}
```

## Project Structure

```
src/
├── daemon/
│   ├── main.jai              # Daemon entry point
│   ├── server.jai            # IPC server + request routing
│   ├── config.jai            # CLI argument parsing
│   ├── context_store.jai     # Thread-safe context state
│   ├── ipc.jai               # Unix sockets / Windows pipes
│   ├── logging.jai           # Logging utilities
│   ├── api/
│   │   ├── context.jai       # context.* handlers
│   │   ├── service.jai       # service.* handlers
│   │   ├── subscription.jai  # subscribe/unsubscribe handlers
│   │   ├── handshake.jai     # Version negotiation
│   │   ├── preview.jai       # preview.* handlers
│   │   └── logs.jai          # logs.* handlers
│   ├── config/
│   │   ├── parser.jai        # TOML config parsing
│   │   └── validator.jai     # Context validation
│   ├── events/
│   │   ├── dispatcher.jai    # Event broadcasting
│   │   └── heartbeat.jai     # Stale connection cleanup
│   ├── platform/
│   │   ├── linux.jai         # XDG paths, systemd
│   │   ├── macos.jai         # Library paths, launchd
│   │   └── windows.jai       # AppData paths, named pipes
│   └── rpc/
│       └── protocol.jai      # JSON-RPC 2.0 implementation
├── cli/
│   └── main.jai              # CLI client
├── sdk/
│   ├── client.jai            # Service SDK
│   └── module.jai
└── ui/                       # UI components (SDL2/Skia)

tests/
├── run_tests.jai             # Test runner
├── unit/                     # Unit tests (351 tests)
└── integration/              # End-to-end tests

deploy/
├── linux/                    # systemd service files
├── macos/                    # launchd plist files
└── windows/                  # PowerShell install scripts
```

## Testing

```bash
# Build and run all tests
jai tests/run_tests.jai
LD_LIBRARY_PATH=$LD_LIBRARY_PATH:./modules/jai-toml-c/toml-c ./tests/run_tests

# Current test count: 351 tests across:
# - IPC layer (sockets, named pipes)
# - JSON-RPC protocol
# - Context API
# - Service registration
# - Subscriptions
# - Handshake/versioning
# - Preview system
# - Execution logs
# - Config parsing
# - Config validation
# - Event dispatcher
# - Heartbeat system
# - Platform-specific code
# - End-to-end integration
```

## License

MIT

## Contributing

Contributions welcome! Please ensure:
- All new code has corresponding tests
- Tests pass (`./tests/run_tests`)
- Code compiles without warnings
- Follow existing code style

