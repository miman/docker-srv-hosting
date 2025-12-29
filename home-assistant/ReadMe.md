# Home Assistant

Running **install.sh** will install Home Assistant.

## Nabu casa Skyconnect

The following block was added in docker compose file to support Nabu casa Skyconnect USB device.

```yaml
      devices:
         - /dev/serial/by-id//usb-Nabu_Casa_SkyConnect_v1.0_0ChangeThis-if00-port0
```

Check your path: Before starting, run **ls /dev/serial/by-id/** in your terminal.

Use the long ID found in that folder (e.g., /dev/serial/by-id/usb-Nabu_Casa_Home_Assistant_Connect_ZBT-1_...). This ensures that if you plug in another USB device later, the "address" of your Zigbee stick doesn't change and break your setup.

## Raspberry PI Bluetooth

The following block was added to docker compose file to support RPI Bluetooth

```yaml
      cap_add:
         - NET_ADMIN
         - NET_RAW
```

# Nginx Proxy Manager config

I had to add the following to the configuration.yaml to be able to add a Proxy Host inNginx for Home Assistant:

```yaml
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 127.0.0.1
    - 172.16.0.0/12 # Docker network
    - 172.18.0.0/16 # Docker network
```