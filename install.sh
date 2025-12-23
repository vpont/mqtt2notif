#!/bin/bash
set -e

# Configuration
SERVICE_NAME="mqtt2notif.service"
SERVICE_FILE="mqtt2notif.service"
INSTALL_DIR="$HOME/.config/systemd/user"
BIN_DIR="$HOME/.local/bin"
SCRIPT_NAME="mqtt2notif.py"

echo "🚀 Installing mqtt2notif Daemon..."

# Create binary directory if it doesn't exist
mkdir -p "$BIN_DIR"

# Copy python script
echo "� Installing script to $BIN_DIR/$SCRIPT_NAME..."
cp "$SCRIPT_NAME" "$BIN_DIR/$SCRIPT_NAME"
chmod +x "$BIN_DIR/$SCRIPT_NAME"

# Create systemd user directory if it doesn't exist
mkdir -p "$INSTALL_DIR"

# Copy service file
echo "📝 Copying service file to $INSTALL_DIR..."
cp "$SERVICE_FILE" "$INSTALL_DIR/"

# Reload systemd
echo "🔄 Reloading systemd..."
systemctl --user daemon-reload

# Enable and start service
echo "✅ Enabling and starting service..."
systemctl --user enable "$SERVICE_NAME"
systemctl --user restart "$SERVICE_NAME"

echo "🎉 Done! Service status:"
systemctl --user status "$SERVICE_NAME" --no-pager
