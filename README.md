# xpad-zhixu-fix

A Linux kernel `xpad` driver patch and DKMS module to fix the continuous idle connect/disconnect loop on **ZhiXu-based Xbox 360 controller clones** (including the **Fantech EOS Pro II / II S**, Machenike G3V2, EasySMX X20, etc.) when connected via wired USB.

---

## The Problem
When connected via USB without a running application (like Steam or Unreal Engine Editor) holding the gamepad's input device node open:
1. `xpad` registers `/dev/input/eventX` but does not submit the interrupt IN URB or start polling until an application issues `open()` on the device.
2. The controller's internal ZhiXu MCU firmware watchdog expects active polling on endpoint `0x81` (standard Windows behavior).
3. After ~1–2 seconds of zero polling, the controller's firmware assumes a connection loss and performs a soft reset, dropping off the USB bus and reconnecting indefinitely.
4. When connected via a 2.4GHz USB wireless dongle, the dongle's transceiver handles the USB bus independently, avoiding this reset loop.

---

## The Solution
This patched driver adds a persistent polling quirk (`xpad->always_poll`):
- Auto-detected for devices with VID `045e`, PID `028e`, and manufacturer string `ZhiXu`.
- Can also be forced for any device via the module option `always_poll=1`.
- Initiates USB interrupt IN polling immediately during `probe()` and sends the required initialization magic packet (`0x01`).
- Preserves active polling across userspace application opens and closes so closing games or Steam will never trigger the disconnect loop.
- Built with `LLVM=1` and `clang` to ensure full native compatibility with CachyOS kernels.

---

## Installation via DKMS

Run the automated installation script:
```bash
sudo ./install.sh
```

Or manually:
```bash
sudo mkdir -p /usr/src/xpad-zhixu-fix-1.0
sudo cp Makefile dkms.conf xpad.c /usr/src/xpad-zhixu-fix-1.0/
sudo dkms add -m xpad-zhixu-fix -v 1.0
sudo dkms build -m xpad-zhixu-fix -v 1.0
sudo dkms install -m xpad-zhixu-fix -v 1.0 --force
sudo modprobe -r xpad && sudo modprobe xpad
```

## Verification
1. Disconnect the 2.4GHz wireless dongle.
2. Connect your Fantech EOS Pro II S controller via the USB-C cable.
3. Check kernel logs:
   ```bash
   journalctl -k -b -n 30
   ```
   You should see:
   ```text
   Enabling persistent polling quirk for ZhiXu / Fantech controller
   ```
4. Verify the controller remains stably connected indefinitely without any game or Steam open.

---

## Uninstallation

To revert to the stock kernel `xpad` driver:
```bash
sudo ./uninstall.sh
```

