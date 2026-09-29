# OpenThread Border Router (OTBR) - Standalone Container

A standalone Docker container for running an OpenThread Border Router without Home Assistant OS, Supervisor, or bashio dependencies. Built from the Home Assistant OTBR add-on and converted for use as an independent service.

## Features

- ✅ Full OpenThread Border Router functionality
- ✅ REST API on port 8081 (Home Assistant integration compatible)
- ✅ Optional Web UI on port 8080
- ✅ Support for USB serial Thread radios (e.g., Silicon Labs)
- ✅ Support for network-connected Thread radios (via TCP)
- ✅ Automatic Thread settings migration across hardware changes
- ✅ Host networking mode for proper IPv6 multicast and mDNS
- ✅ Add-on defaults preserved, so omitting a variable behaves like the add-on

## Quick Start

### Using USB Serial Radio

```yaml
services:
  otbr:
    container_name: otbr
    image: ghcr.io/d34dc3n73r/ha-otbr:stable
    restart: unless-stopped
    network_mode: host
    cap_add:
      - NET_ADMIN
      - IPC_LOCK
    environment:
      DEVICE: "/dev/ttyUSB0"              # Your Thread radio device
      BACKBONE_IF: eth0                   # Your primary network interface
      OTBR_REST_PORT: 8081                # Enable REST API on network (required for HA)
      OTBR_WEB_PORT: 8080                 # Enable Web UI (Optional - Remove to disable)
      FLOW_CONTROL: 1                     # Hardware flow control (1=enabled)
      BAUDRATE: 460800                    # Serial baudrate
      FIREWALL: 1                         # Enable Thread firewall
      NAT64: 1                            # Enable NAT64 for Thread devices
      BETA: 0                             # Beta mode: 0=stable OTBR build, 1=pre-release OTBR build
      OTBR_LOG_LEVEL: info                # Log level: debug|info|notice|warning|error
    devices:
      - /dev/ttyUSB0                      # Expose your Thread radio
      - /dev/net/tun                      # Required for Thread networking
    volumes:
      - ./otbr-data:/data/thread          # Persist Thread network settings
      - /etc/localtime:/etc/localtime:ro
```

### Using Network Radio (TCP)

```yaml
services:
  otbr:
    container_name: otbr
    image: ghcr.io/d34dc3n73r/ha-otbr:stable
    restart: unless-stopped
    network_mode: host
    cap_add:
      - NET_ADMIN
      - IPC_LOCK
    environment:
      NETWORK_DEVICE: "192.168.1.100:6638" # TCP address of Thread radio
      BACKBONE_IF: eth0
      OTBR_REST_PORT: 8081
      OTBR_WEB_PORT: 8080
      FLOW_CONTROL: 1
      BAUDRATE: 460800
      FIREWALL: 1
      NAT64: 1
      BETA: 0                             # Beta: pre-release OTBR build
    devices:
      - /dev/net/tun
    volumes:
      - ./otbr-data:/data/thread
      - /etc/localtime:/etc/localtime:ro
```

## Environment Variables

Every variable below falls back to the same default the Home Assistant add-on
uses, so omitting one behaves like the add-on rather than silently disabling
the feature.

> **⚠️ Upgrade note:** earlier images treated an unset variable as "off".
> `FLOW_CONTROL` and `FIREWALL` now default to **enabled**, matching the add-on.
> If you were relying on the old behaviour — most notably a radio wired without
> hardware flow control — set `FLOW_CONTROL: 0` explicitly.

### Required

| Variable | Description | Example |
|----------|-------------|---------|
| `DEVICE` | Serial device path for Thread radio (or set `NETWORK_DEVICE`) | `/dev/ttyUSB0` |

The container exits at startup if neither `DEVICE` nor `NETWORK_DEVICE` is set.

| Variable | Description | Default |
|----------|-------------|---------|
| `BACKBONE_IF` | Primary network interface name | Interface holding the default route |

If `BACKBONE_IF` is unset and no default route can be found, the container exits
rather than guessing — a wrong backbone interface produces a border router that
starts cleanly and routes nothing.

### Optional Services

| Variable | Description | Default |
|----------|-------------|---------|
| `OTBR_REST_PORT` | Enable REST API on all interfaces (must be `8081`) | `8081` (localhost only if unset) |
| `OTBR_WEB_PORT` | Enable Web UI (can be any port) | Disabled if unset |

### Radio Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `NETWORK_DEVICE` | TCP address for network radios (e.g., `192.168.1.10:6638`) | USB serial if unset |
| `BAUDRATE` | Serial baudrate | `460800` |
| `FLOW_CONTROL` | Hardware flow control | `1` (enabled) |

### Network & Security

| Variable | Description | Default |
|----------|-------------|---------|
| `FIREWALL` | Enable Thread ingress firewall | `1` (enabled) |
| `NAT64` | Enable NAT64 for Thread IPv6→IPv4 | `0` (disabled) |
| `OTBR_LOG_LEVEL` | Log verbosity: `debug`, `info`, `notice`, `warning`, `error`, `critical`, `alert`, `emergency`. Applies to both `otbr-agent` and the Web UI. | `notice` |

Booleans accept `1`/`true`/`yes`/`on` and `0`/`false`/`no`/`off`, case-insensitively.

### Advanced Features

| Variable | Description | Default |
|----------|-------------|---------|
| `BETA` | Run the pre-release OTBR build instead of the stable one. Set to `1` or `true` to enable. | `0` (disabled) |

> **⚠️ Beta Mode Warning**
>
> Beta mode runs a newer, unreleased OpenThread Border Router build (currently `v2026.09.0`, with ePSKc / Thread 1.4 Credentials Sharing in the Web UI). It may have stability or compatibility issues — use stable mode (default) for production systems.
>
> **Changed in HA OTBR 3.0.0:** Thread 1.4 and OpenThread's built-in mDNS are now used in **both** stable and beta mode, and `mDNSResponder` is gone. `BETA` no longer selects the Thread version — it only selects a newer OTBR build. Thread 1.4 firmware is required on your radio either way.

## Port Configuration

### REST API (Port 8081)
The REST API **must run on port 8081** as the Web UI and Home Assistant integration expect this port.

- **Set `OTBR_REST_PORT: 8081`** → API binds to all interfaces (accessible from network)
- **Unset `OTBR_REST_PORT`** → API binds to localhost only (secure default)

### Web UI (Port 8080)
The Web UI can run on any port and is completely optional.

- **Set `OTBR_WEB_PORT: 8080`** → Web UI enabled on specified port
- **Unset `OTBR_WEB_PORT`** → Web UI disabled

## Accessing Services

- **Web UI**: `http://<host-ip>:8080` (if `OTBR_WEB_PORT` is set)
- **REST API**: `http://<host-ip>:8081/node` (if `OTBR_REST_PORT` is set)
- **Home Assistant**: Add OTBR integration pointing to `http://<host-ip>:8081`

## Network Requirements

- **Host networking mode required** (`network_mode: host`) for:
  - Proper IPv6 multicast routing
  - mDNS service discovery
  - Thread TREL (Thread Radio Encapsulation Link)

- **Do not set a custom `hostname:`.** OTBR publishes itself over mDNS as
  `<hostname>-otbr`. With `network_mode: host` Docker gives the container the
  host's hostname, so that name is already stable across recreates — overriding
  it, or dropping host networking, makes the published name drift.

- **Capabilities.** The add-on grants only `NET_ADMIN` and `IPC_LOCK`. `NET_RAW`
  is already in Docker's default capability set, and `SYS_ADMIN` should not be
  needed — if s6 fails to start on your host, add it back and please open an issue.

### Host System Configuration

The following sysctl settings **must be configured on the Docker host** for proper IPv6 and routing functionality:

```bash
# Enable IPv6
net.ipv6.conf.all.disable_ipv6=0

# Enable IP forwarding (required for Thread routing)
net.ipv4.conf.all.forwarding=1
net.ipv6.conf.all.forwarding=1

# IPv6 router advertisements (required for Thread prefix delegation)
net.ipv6.conf.all.accept_ra=2
net.ipv6.conf.all.accept_ra_rt_info_max_plen=64
```

**To apply these settings:**

Temporary (until reboot):
```bash
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=0
sudo sysctl -w net.ipv4.conf.all.forwarding=1
sudo sysctl -w net.ipv6.conf.all.forwarding=1
sudo sysctl -w net.ipv6.conf.all.accept_ra=2
sudo sysctl -w net.ipv6.conf.all.accept_ra_rt_info_max_plen=64
```

Permanent (survives reboot):
```bash
sudo tee -a /etc/sysctl.d/99-otbr.conf > /dev/null <<EOF
net.ipv6.conf.all.disable_ipv6=0
net.ipv4.conf.all.forwarding=1
net.ipv6.conf.all.forwarding=1
net.ipv6.conf.all.accept_ra=2
net.ipv6.conf.all.accept_ra_rt_info_max_plen=64
EOF
sudo sysctl -p /etc/sysctl.d/99-otbr.conf
```

## Data Persistence

Thread network settings are stored in `/data/thread/`:
- Mount a volume to persist across container restarts
- Settings are automatically migrated when hardware changes (same network credentials)

## Home Assistant Integration

There is no Supervisor to push discovery, so add the border router by URL:

1. In Home Assistant, go to **Settings → Devices & Services → Add Integration**
2. Search for **"OpenThread Border Router"**
3. Enter `http://<host-ip>:8081`
4. The Thread network will be set up automatically

This requires `OTBR_REST_PORT: 8081`; without it the REST API only listens on
localhost and Home Assistant cannot reach it. The container logs the exact URL
to use on startup.

## Troubleshooting

### Finding Your Network Interface
```bash
ip route show default
```
Look for the interface name after `dev` (e.g., `eth0`, `enp5s0`).

### Finding Your Thread Radio
```bash
ls -la /dev/ttyUSB* /dev/ttyACM*
```

### Checking Logs
```bash
docker logs -f otbr
```

### Testing REST API
```bash
curl http://localhost:8081/node
```

## Building from Source

```bash
git clone https://github.com/D34DC3N73R/ha-otbr.git
cd ha-otbr
docker build -t ha-otbr .
```

## License

See [LICENSE](LICENSE) file.

## Credits

Based on the [Home Assistant OTBR Add-on](https://github.com/home-assistant/addons/tree/master/openthread_border_router), converted to a standalone container.

