&nbsp; Windows Commands Reference



&nbsp; Installation (first time)



&nbsp; # From project directory, in PowerShell:

&nbsp; cd deploy\\windows

&nbsp; .\\install.ps1 -Startup          # Install as startup app (recommended)

&nbsp; # OR

&nbsp; .\\install.ps1 -Service          # Install as Windows service (requires admin)



&nbsp; Update/Reinstall



&nbsp; cd deploy\\windows

&nbsp; .\\install.ps1 -Update           # Updates binaries, preserves config, restarts automatically

&nbsp; # OR

&nbsp; .\\install.ps1 -Dev              # Build + update (for development)



&nbsp; Process Management (if installed as Startup app)



&nbsp; # Check if running:

&nbsp; Get-Process uncrumpled\*



&nbsp; # Stop:

&nbsp; Stop-Process -Name uncrumpled\* -Force



&nbsp; # Start:

&nbsp; Start-Process "$env:LOCALAPPDATA\\uncrumpled-context-switcher\\uncrumpled-context-switcher.exe"



&nbsp; # Restart:

&nbsp; Stop-Process -Name uncrumpled\* -Force; Start-Sleep 1; Start-Process "$env:LOCALAPPDATA\\uncrumpled-context-switcher\\uncrumpled-context-switcher.exe"



&nbsp; Service Management (if installed as Service - requires admin)



&nbsp; # Status:

&nbsp; Get-Service UncrumpledContextSwitcherDaemon



&nbsp; # Stop:

&nbsp; Stop-Service UncrumpledContextSwitcherDaemon



&nbsp; # Start:

&nbsp; Start-Service UncrumpledContextSwitcherDaemon



&nbsp; # Restart:

&nbsp; Restart-Service UncrumpledContextSwitcherDaemon



&nbsp; View Logs



&nbsp; # View last 50 lines:

&nbsp; Get-Content "$env:LOCALAPPDATA\\uncrumpled-context-switcher\\logs\\daemon.log" -Tail 50



&nbsp; # Follow logs in real-time (like tail -f):

&nbsp; Get-Content "$env:LOCALAPPDATA\\uncrumpled-context-switcher\\logs\\daemon.log" -Wait



&nbsp; # View last 100 lines:

&nbsp; Get-Content "$env:LOCALAPPDATA\\uncrumpled-context-switcher\\logs\\daemon.log" -Tail 100



&nbsp; Uninstall



&nbsp; cd deploy\\windows

&nbsp; .\\install.ps1 -Uninstall



&nbsp; Paths



&nbsp; - Installation: %LOCALAPPDATA%\\uncrumpled-context-switcher\\

&nbsp; - Config: %APPDATA%\\uncrumpled-context-switcher\\config.toml

&nbsp; - Logs: %LOCALAPPDATA%\\uncrumpled-context-switcher\\logs\\daemon.log



&nbsp; Note: For the install script to work properly, you'll need to manually copy the DLLs (skia.dll, skia\_ref\_helper.dll) and fonts/ folder to the install

&nbsp; directory the first time, or I can try to add that to the script again later when the file isn't being modified.

