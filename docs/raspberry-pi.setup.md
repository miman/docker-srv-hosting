# Raspberry Pi Setup

## Do before starting the pi

After flashing, mount the SD card and create an empty file named **ssh** (no extension) in the boot partition. This enables SSH on first boot.

## Disable the GUI on Boot

If you want to keep your existing Raspberry Pi OS installation (with desktop) but disable the graphical user interface (GUI) from starting at boot, you can use the **raspi-config** tool. 

This way, your Pi will boot directly to the command line, saving resources for server tasks.

## Steps to Disable the GUI on Boot

Open the configuration tool:
```bash
sudo raspi-config
```

Navigate to:

System Options > Boot / Auto Login > Console Autologin
(This ensures the Pi boots to the command line instead of the desktop.)


Reboot your Pi:
```bash
sudo reboot
```


After rebooting, your Raspberry Pi will start in text mode (no GUI)

## Result

The raspi-config tool changes the boot target to multi-user.target (text mode) instead of graphical.target (GUI).

This is reversible—you can re-enable the GUI anytime using the same tool.

## StartUI

You can still manually start the desktop later if needed by running:
```bash
startx
```