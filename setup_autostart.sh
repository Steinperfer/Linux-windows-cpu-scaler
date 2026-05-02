#!/bin/bash

# Autostart setup script for cpu_scaling.sh with sudo privileges
# Works on Arch Linux and Ubuntu (systemd-based systems)

SCRIPT_PATH="/home/martin/Schreibtisch/Aider/cpu_scaling.sh"
SERVICE_NAME="cpu-scaling"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

echo "Setting up autostart for CPU scaling script..."

# Check if script exists
if [ ! -f "$SCRIPT_PATH" ]; then
    echo "Error: $SCRIPT_PATH not found!"
    exit 1
fi

# Make sure script is executable
chmod +x "$SCRIPT_PATH"

# Create systemd service file (requires sudo)
echo "Creating systemd service file..."
sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=Windows-like CPU frequency scaling
After=multi-user.target

[Service]
Type=simple
ExecStart=$SCRIPT_PATH
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start service
echo "Enabling and starting service..."
sudo systemctl daemon-reload
sudo systemctl enable "$SERVICE_NAME"
sudo systemctl start "$SERVICE_NAME"

echo "Done! Service status:"
sudo systemctl status "$SERVICE_NAME" --no-pager

echo ""
echo "To check logs: sudo journalctl -u $SERVICE_NAME -f"
echo "To stop: sudo systemctl stop $SERVICE_NAME"
echo "To disable autostart: sudo systemctl disable $SERVICE_NAME"
