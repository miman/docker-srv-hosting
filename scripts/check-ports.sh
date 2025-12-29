#!/bin/bash
set -e

echo "Checking for all occupied TCP and UDP ports..."
echo "=============================================="
echo "Note: This command may require 'sudo' to show process information for all ports."
echo ""

# ss is the modern tool to investigate sockets.
# -t: TCP sockets
# -u: UDP sockets
# -l: Display listening sockets.
# -p: Show process using socket.
# -n: Do not try to resolve service names.
if command -v ss &> /dev/null; then
    sudo ss -tulpn
elif command -v netstat &> /dev/null; then
    echo "ss command not found, falling back to netstat..."
    sudo netstat -tulpn
else
    echo "Error: Neither 'ss' nor 'netstat' command found. Cannot check for open ports."
    exit 1
fi

echo "=============================================="
echo "Done."
