#!/bin/bash
set -e

if [ "$EUID" -ne 0 ]; then
    echo "[!] Please run with sudo or as root: sudo ./install.sh"
    exit 1
fi

DEST_DIR="/usr/src/xpad-fantech-1.0"
echo "[*] Preparing DKMS source directory at $DEST_DIR..."
mkdir -p "$DEST_DIR"
cp Makefile dkms.conf xpad.c "$DEST_DIR/"

echo "[*] Registering xpad-fantech with DKMS..."
if dkms status -m xpad-fantech -v 1.0 | grep -q "added\|built\|installed"; then
    echo "[*] Previous DKMS registration found. Removing old version..."
    dkms remove -m xpad-fantech -v 1.0 --all || true
fi

dkms add -m xpad-fantech -v 1.0

echo "[*] Building xpad-fantech via DKMS..."
dkms build -m xpad-fantech -v 1.0

echo "[*] Installing xpad-fantech via DKMS..."
dkms install -m xpad-fantech -v 1.0 --force

echo "[*] Reloading xpad kernel module..."
if lsmod | grep -q "^xpad "; then
    modprobe -r xpad || echo "[!] Could not unload xpad automatically (in use?). A reboot will apply the new driver."
fi
modprobe xpad || echo "[!] Could not load xpad. A reboot will apply the new driver."

echo "[✓] Installation complete!"
echo "[*] Active module path: $(modinfo -F filename xpad 2>/dev/null || echo 'N/A')"
echo "[*] You can now plug in your Fantech EOS Pro II S controller via USB-C."

