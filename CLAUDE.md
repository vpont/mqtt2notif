# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

mqtt2notif is a Python daemon that subscribes to an MQTT broker and displays received notifications on Linux desktop using libnotify. It complements the **Notif2MQTT** Android app, which captures Android notifications and publishes them to MQTT.

**Tech Stack**: Python 3, paho-mqtt (MQTT client), PyGObject (libnotify bindings), Pillow (image processing), systemd

## Common Commands

### Running the Daemon

```bash
# Initialize configuration (first time)
python3 mqtt2notif.py --init-config

# Run in foreground with verbose output
python3 mqtt2notif.py --verbose

# Run in daemon mode
python3 mqtt2notif.py --daemon
```

### Systemd Service Management

```bash
# Install as systemd user service
./install.sh

# Check service status
systemctl --user status mqtt2notif

# View logs
journalctl --user -u mqtt2notif -f

# Restart service
systemctl --user restart mqtt2notif

# Stop service
systemctl --user stop mqtt2notif

# Uninstall service
./uninstall.sh
```

### Testing & Development

```bash
# Test MQTT connection manually
mosquitto_sub -h localhost -t "notif2mqtt/notifications" -v

# Test notification display
python3 -c "
import gi
gi.require_version('Notify', '0.7')
from gi.repository import Notify
Notify.init('test')
n = Notify.Notification.new('Test', 'Hello World')
n.show()
"

# Check libnotify installation
which notify-send
notify-send "Test" "Notification test"
```

## Architecture Overview

The daemon uses an **event-driven MQTT subscriber architecture**:

```
MQTT Broker
    ↓
mqtt2notif.py (MQTT subscriber)
    ↓
Message Parser (JSON)
    ↓
Image Decoder (Base64 → PNG)
    ↓
libnotify (desktop notifications)
    ↓
Desktop Notification Display
```

## Key Components

### MQTT Client

- **Library**: paho-mqtt
- **Connection**: Supports both TCP and SSL/TLS
- **QoS**: Subscribes with QoS 1 (at-least-once delivery)
- **Topics**: Configurable via `config.ini`
- **Reconnection**: Automatic reconnection on connection loss

### Configuration Management

- **Location**: `~/.config/mqtt2notif/config.ini` (XDG compliant)
- **Format**: INI file with `[mqtt]` section
- **Loading**: `load_config()` function reads and validates settings
- **Initialization**: `--init-config` flag creates default config

### Notification Display

- **Library**: libnotify via PyGObject
- **Features**:
  - Icon display from Base64-encoded PNG/JPEG
  - Preview image support with composite rendering
  - Urgency level mapping (critical, normal, low)
  - Notification categories
  - Temporary file cleanup

### Image Processing

- **Icon Handling**: Decode Base64 → attach to notification
- **Preview Images**: Optional Pillow-based composite (icon overlaid on preview)
- **Formats**: PNG, JPEG
- **Cleanup**: Temporary files removed after notification display

## Data Flow

1. **MQTT Connection**: Connect to broker with configured credentials
2. **Topic Subscription**: Subscribe to configured topic (default: `notif2mqtt/notifications`)
3. **Message Reception**: Receive JSON payload via MQTT callback
4. **JSON Parsing**: Parse notification fields (app, title, text, icon, urgency, etc.)
5. **Image Decoding**: Decode Base64 icon/preview images to temporary files
6. **Notification Creation**: Create libnotify notification with metadata
7. **Display**: Show notification on desktop with appropriate urgency
8. **Cleanup**: Remove temporary image files

## Data Model

### Incoming JSON Format

```json
{
  "package": "com.example.app",
  "app": "App Name",
  "title": "Notification Title",
  "text": "Notification body text",
  "timestamp": 1703001234567,
  "icon": "base64-encoded-png-data",
  "previewImage": "base64-encoded-image-data",
  "importance": 4,
  "urgency": "high",
  "category": "msg"
}
```

### Urgency Mapping

```python
# Android importance (0-5) → libnotify urgency
{
    "critical": Notify.Urgency.CRITICAL,  # importance 5
    "high": Notify.Urgency.CRITICAL,      # importance 4
    "normal": Notify.Urgency.NORMAL,      # importance 3
    "low": Notify.Urgency.LOW,            # importance 1-2
    "minimal": Notify.Urgency.LOW         # importance 0
}
```

## Important Design Decisions

1. **XDG Compliance**: Configuration stored in `~/.config/mqtt2notif/` following XDG Base Directory specification for Linux standards compliance.

2. **Systemd Integration**: Runs as a systemd user service (not system service) to access user's notification daemon and DBUS session.

3. **QoS 1**: MQTT subscription uses QoS 1 (at-least-once) to ensure notifications aren't missed due to network issues. May result in duplicate notifications on reconnection.

4. **Temporary Files**: Icons saved to `/tmp/notif_*.png` because libnotify requires file paths. Files are cleaned up after display to prevent disk space issues.

5. **Auto-Reconnect**: MQTT client automatically reconnects on connection loss with exponential backoff via paho-mqtt's built-in reconnection logic.

6. **Color-Coded Output**: Console uses ANSI colors for debugging (info=cyan, warning=yellow, error=red) to improve log readability during development.

7. **Optional Pillow**: Pillow dependency is optional - basic notifications work without it. Only needed for composite image features (icon overlaid on preview).

## File Organization

```
mqtt2notif/
├── mqtt2notif.py           # Main daemon script
├── install.sh              # Systemd installation script
├── uninstall.sh            # Systemd removal script
├── mqtt2notif.service      # Systemd user service definition
├── requirements.txt        # Python dependencies
├── README.md               # User documentation
├── CLAUDE.md               # Developer guidance (this file)
└── LICENSE                 # GPL-3.0 license
```

## Configuration File Structure

```ini
[mqtt]
broker = localhost          # MQTT broker hostname/IP
port = 1883                 # MQTT broker port (1883 or 8883 for SSL)
ssl = false                 # Enable SSL/TLS encryption
topic = notif2mqtt/notifications  # MQTT topic to subscribe
username =                  # Optional MQTT authentication
password =                  # Optional MQTT password
```

## Dependencies

### System Dependencies

- **libnotify**: Desktop notification system
- **PyGObject**: Python GObject bindings for libnotify
- **Python 3.7+**: Interpreter

### Python Dependencies

- **paho-mqtt** (1.6.1+): MQTT client library
- **PyGObject**: GObject Introspection bindings
- **Pillow** (optional): Image processing for composites

## Troubleshooting Development Issues

### "ModuleNotFoundError: No module named 'gi'"

Install PyGObject:

```bash
# Arch
sudo pacman -S python-gobject

# Ubuntu/Debian
sudo apt install python3-gi gir1.2-notify-0.7
```

### "Notify.init() must be called before creating notifications"

Ensure `Notify.init('mqtt2notif')` is called before creating any notifications. This is handled in `main()`.

### "Connection refused" or MQTT connection fails

- Verify MQTT broker is running: `systemctl status mosquitto`
- Check broker port is correct (1883 for TCP, 8883 for SSL)
- Test connectivity: `mosquitto_sub -h <broker> -t "#" -v`
- Verify credentials if authentication is enabled
- Check firewall rules

### Notifications not displaying

- Ensure notification daemon is running (usually automatic in desktop environments)
- Test libnotify: `notify-send "Test" "Hello"`
- Check systemd service logs: `journalctl --user -u mqtt2notif -f`
- Verify DBUS session is accessible

### "Pillow not installed" warning

Optional dependency - install if you want composite images:

```bash
pip install --user Pillow
```

### Icons not displaying

- Check `/tmp/notif_*.png` files are created
- Verify Base64 data is valid PNG/JPEG
- Ensure `/tmp` is writable
- Check file cleanup isn't removing files prematurely

## Testing

**Current Status**: No automated tests configured.

**Recommendations**:

- Unit tests for JSON parsing
- Unit tests for Base64 image decoding
- Unit tests for urgency mapping
- Mock tests for MQTT callbacks
- Integration tests with test MQTT broker
- End-to-end tests with libnotify mocking

## Related Projects

**Notif2MQTT**: Android app that captures notifications and publishes them to MQTT. This daemon is designed to receive and display those notifications on Linux.

- Repository: https://github.com/vpont/Notif2MQTT
- Together they form: Android → MQTT → Linux Desktop notification bridge

## Recent Updates

**Latest Changes**:

- Split from Notif2MQTT monorepo into independent mqtt2notif project
- Configuration path changed to `~/.config/mqtt2notif/` for naming consistency
- Updated all scripts to use `mqtt2notif` naming
- Improved documentation for standalone usage
