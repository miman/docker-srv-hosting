# Headplane

Headplane is a web interface for Headscale.

## Installation

```bash
./install.sh
```

## Observe

This script assumes your headscale is running and accessible at `https://headscale.$BASE_DNS_NAME`, if this isn't the case, please change the following part in the install-script before running it:

```bash
headscale:
  url: "https://headscale.$BASE_DNS_NAME"
  ...
```
