#!/bin/bash

SCRIPT_NAME="cpu_scaling.sh"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_NAME"
SERVICE_NAME="cpu-scaling"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

echo "Setting up autostart for CPU scaling script..."

if [ ! -f "$SCRIPT_PATH" ]; then
    echo "Error: $SCRIPT_NAME not found!"
    exit 1
fi

chmod +x "$SCRIPT_PATH"

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