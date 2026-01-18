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
- ✅ Clean, minimal logs with filtered noise

## Quick Start

### Using USB Serial Radio

```yaml
services:
  otbr:
    container_name: otbr
    image: ghcr.io/d34dc3n73r/ha-otbr:latest
    restart: unless-stopped
    network_mode: host
    cap_add:
      - SYS_ADMIN
      - NET_ADMIN
      - NET_RAW
    environment:
      DEVICE: "/dev/ttyUSB0"              # Your Thread radio device
      BACKBONE_IF: eth0                   # Your primary network interface
      OTBR_REST_PORT: 8081                # Enable REST API on network (required for HA)
      OTBR_WEB_PORT: 8080                 # Enable Web UI (Optional - Remove to disable)
      FLOW_CONTROL: 1                     # Hardware flow control (1=enabled)
      BAUDRATE: 460800                    # Serial baudrate
      FIREWALL: 1                         # Enable Thread firewall
      NAT64: 1                            # Enable NAT64 for Thread devices
      OTBR_LOG_LEVEL: info                # Log level: debug|info|warning|error
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
    image: ghcr.io/d34dc3n73r/ha-otbr:latest
    restart: unless-stopped
    network_mode: host
    cap_add:
      - SYS_ADMIN
      - NET_ADMIN
      - NET_RAW
    environment:
      NETWORK_DEVICE: "192.168.1.100:6638" # TCP address of Thread radio
      BACKBONE_IF: eth0
      OTBR_REST_PORT: 8081
      OTBR_WEB_PORT: 8080
      FLOW_CONTROL: 1
      BAUDRATE: 460800
      FIREWALL: 1
      NAT64: 1
    devices:
      - /dev/net/tun
    volumes:
      - ./otbr-data:/data/thread
      - /etc/localtime:/etc/localtime:ro
```

## Environment Variables

### Required

| Variable | Description | Example |
|----------|-------------|---------|
| `DEVICE` | Serial device path for Thread radio | `/dev/ttyUSB0` |
| `BACKBONE_IF` | Primary network interface name | `eth0` |

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
| `FLOW_CONTROL` | Hardware flow control (1=enabled, 0=disabled) | `1` |

### Network & Security

| Variable | Description | Default |
|----------|-------------|---------|
| `FIREWALL` | Enable Thread ingress firewall | `1` |
| `NAT64` | Enable NAT64 for Thread IPv6→IPv4 | `1` |
| `OTBR_LOG_LEVEL` | Log verbosity: `debug`, `info`, `warning`, `error` | `info` |

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

1. In Home Assistant, go to **Settings → Devices & Services → Add Integration**
2. Search for **"OpenThread Border Router"**
3. Enter the container's IP address and port `8081`
4. The Thread network will be discovered automatically

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

