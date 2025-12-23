#!/bin/bash
set -e

# Configuration
SERVICE_NAME="mqtt2notif.service"
SERVICE_FILE="mqtt2notif.service"
INSTALL_DIR="$HOME/.config/systemd/user"
BIN_DIR="$HOME/.local/bin"
SCRIPT_NAME="mqtt2notif.py"

echo "🗑️ Uninstalling mqtt2notif Daemon..."

# Stop and disable service
echo "🛑 Stopping service..."
systemctl --user stop "$SERVICE_NAME" || true
systemctl --user disable "$SERVICE_NAME" || true

# Remove service file
if [ -f "$INSTALL_DIR/$SERVICE_FILE" ]; then
    echo "📄 Removing service file..."
    rm "$INSTALL_DIR/$SERVICE_FILE"
fi

# Remove python script
if [ -f "$BIN_DIR/$SCRIPT_NAME" ]; then
    echo "🗑️ Removing binary..."
    rm "$BIN_DIR/$SCRIPT_NAME"
fi

# Reload systemd
echo "🔄 Reloading systemd..."
systemctl --user daemon-reload

echo "✅ Uninstallation complete!"
