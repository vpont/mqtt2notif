# mqtt2notif

A lightweight Python daemon that receives Android notifications from MQTT and displays them on Linux desktop using libnotify.

## Features

- 📡 **MQTT Subscriber**: Receives notifications from MQTT broker
- 🔔 **Native Notifications**: Uses libnotify for desktop integration
- 🔒 **Secure Connections**: Support for SSL/TLS encrypted MQTT
- 🎨 **Icon Support**: Displays Base64-encoded notification icons
- 🖼️ **Preview Images**: Shows preview images with composite overlays
- 🎯 **Urgency Mapping**: Respects notification importance levels
- ⚙️ **Systemd Integration**: Run as a user service with auto-restart
- 📁 **XDG Compliant**: Configuration follows XDG Base Directory spec
- 🎨 **Color Output**: Color-coded console logging for debugging

## Requirements

- Python 3.7+
- libnotify (notification system)
- PyGObject (GObject bindings for Python)
- paho-mqtt (MQTT client library)
- MQTT Broker (e.g., Mosquitto)
- Pillow (optional, for composite images)

## Installation

### Install System Dependencies

**Arch Linux:**

```bash
sudo pacman -S python-gobject python-paho-mqtt python-pillow libnotify
```

**Ubuntu/Debian:**

```bash
sudo apt install python3-gi python3-paho-mqtt python3-pillow gir1.2-notify-0.7 libnotify-bin
```

### Install as Systemd Service

```bash
./install.sh
```

This will:

- Install dependencies
- Copy `mqtt2notif.py` to `~/.local/bin/`
- Install systemd service to `~/.config/systemd/user/`
- Enable and start the service

## Configuration

mqtt2notif reads configuration from `~/.config/mqtt2notif/config.ini` (or `$XDG_CONFIG_HOME/mqtt2notif/config.ini`).

### Create Default Configuration

```bash
./mqtt2notif.py --init-config
```

This creates a configuration file with defaults:

```ini
[mqtt]
broker = localhost
port = 1883
ssl = false
username =
password =
```

### Configuration Options

- **broker**: MQTT broker hostname or IP address
- **port**: MQTT broker port (1883 for unencrypted, 8883 for SSL)
- **ssl**: Enable SSL/TLS encryption (`true` or `false`)
- **username**: MQTT authentication username (optional)
- **password**: MQTT authentication password (optional)

## Usage

### Run in Foreground (Debug Mode)

```bash
./mqtt2notif.py
```

### Run as Daemon

```bash
./mqtt2notif.py --daemon
```

### Run with Systemd

```bash
# Start service
systemctl --user start mqtt2notif

# Check status
systemctl --user status mqtt2notif

# View logs
journalctl --user -u mqtt2notif -f

# Stop service
systemctl --user stop mqtt2notif
```

## MQTT Message Format

mqtt2notif expects notifications in JSON format:

```json
{
  "package": "com.whatsapp",
  "app": "WhatsApp",
  "title": "New message",
  "text": "Hello, how are you?",
  "timestamp": 1703001234567,
  "icon": "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACA...",
  "previewImage": "iVBORw0KGgoAAAANSUhEUgAAAQAAAAEA...",
  "importance": 4,
  "urgency": "high",
  "category": "msg"
}
```

### Urgency Levels

The daemon maps urgency levels to libnotify priorities:

- **high** / **critical**: `Notify.Urgency.CRITICAL` (stays visible)
- **normal**: `Notify.Urgency.NORMAL` (standard behavior)
- **low** / **minimal**: `Notify.Urgency.LOW` (less intrusive)

### Notification Categories

Supported Android categories:

- **msg**: Message notifications
- **email**: Email notifications
- **call**: Incoming call
- **alarm**: Alarm or timer
- **social**: Social network notifications
- **promo**: Promotional notifications
- **event**: Calendar events
- **transport**: Travel/transportation updates

## Related Projects

This daemon is designed to work with **[Notif2MQTT](https://github.com/yourusername/Notif2MQTT)**, an Android app that captures device notifications and sends them to an MQTT broker.

Together they enable:

```
Android Device → Notif2MQTT App → MQTT Broker → mqtt2notif → Linux Desktop
```

## Uninstallation

```bash
./uninstall.sh
```

This will:

- Stop and disable the systemd service
- Remove the service file
- Remove the installed binary

Configuration file (`~/.config/mqtt2notif/config.ini`) is preserved.

## Troubleshooting

### No notifications appearing

1. Check the service is running:

   ```bash
   systemctl --user status mqtt2notif
   ```

2. Check logs for errors:

   ```bash
   journalctl --user -u mqtt2notif -f
   ```

3. Verify MQTT broker connectivity:
   ```bash
   # Test with mosquitto_sub
   mosquitto_sub -h localhost -t "notif2mqtt/notifications" -v
   ```

### SSL/TLS connection fails

- Verify broker SSL configuration
- Check certificate validity
- Ensure port is correct (typically 8883 for SSL)

### Pillow warnings

If you see "composite images won't work" warning:

```bash
pip install --user Pillow
```

This is optional - basic notifications work without it.

## Development

### Run in Verbose Mode

```bash
./mqtt2notif.py --verbose
```

### Configuration File Location

Priority order:

1. `$XDG_CONFIG_HOME/mqtt2notif/config.ini`
2. `~/.config/mqtt2notif/config.ini`

## License

GNU General Public License v3.0 - see [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please open an issue or pull request.
