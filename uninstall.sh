#!/bin/bash
set -e

if [ "$EUID" -ne 0 ]; then
    echo "[!] Please run with sudo or as root: sudo ./uninstall.sh"
    exit 1
fi

echo "[*] Removing xpad-zhixu-fix from DKMS..."
dkms remove -m xpad-zhixu-fix -v 1.0 --all || true

echo "[*] Removing /usr/src/xpad-zhixu-fix-1.0..."
rm -rf /usr/src/xpad-zhixu-fix-1.0

echo "[*] Reloading stock xpad kernel module..."
if lsmod | grep -q "^xpad "; then
    modprobe -r xpad || echo "[!] Could not unload xpad. A reboot will restore the stock driver."
fi
modprobe xpad || echo "[!] Could not load stock xpad."

echo "[✓] Uninstalled. Stock xpad module restored."

