# Booterizer Docker

Network boot server for installing IRIX on SGI hardware via direct ethernet cable.

## Quick Start

### 1. Get Your SGI's MAC Address

On the SGI PROM:
```
printenv eaddr
```
Note the MAC address (format: `08:00:69:xx:xx:xx`)

### 2. Set Up Host Networking

```bash
# Find your ethernet interface name
ip link show

# Configure interface and apply sysctl settings
sudo ./setup-host.sh eth0 172.16.42.1
```

### 3. Populate IRIX Media

**Option A: Automatic Download (Recommended)**

Use the fetch script to download from the SGI archive mirror:
```bash
# Standard installation (overlay + foundation + NFS)
sudo ./fetch-media.sh

# Minimal (just enough to boot and partition)
sudo ./fetch-media.sh --preset minimal

# Full (includes MIPSPro development tools)
sudo ./fetch-media.sh --preset full

# For IRIX 6.5.22 instead of 6.5.30
sudo ./fetch-media.sh --version 6.5.22
```

**Option B: Manual Setup**

Place your IRIX installation files in `/srv/irix` on the host:
```
/srv/irix/
├── 6.5.30/
│   └── Overlay/
│       └── disc1/
│           ├── stand/
│           │   └── fx.64      # Partitioner
│           └── dist/          # Installation files
├── Foundation/
│   └── disc1/
│       └── dist/
└── ... other media
```

### 4. Start the Container

```bash
# Build and start with your SGI's MAC address
docker-compose build
SGI_MAC=08:00:69:xx:xx:xx docker-compose up -d
```

Or create a `.env` file (recommended for repeated use):
```bash
cp .env.example .env
# Edit .env with your settings
docker-compose up -d
```

### 5. Boot Your SGI

On the SGI PROM:
```
setenv netaddr 172.16.42.2
bootp():/6.5.30/Overlay/disc1/stand/fx.64
```

## Environment Variables

All configuration is done via environment variables. No need to edit config files.

| Variable | Default | Description |
|----------|---------|-------------|
| `SGI_MAC` | `08:00:69:00:00:00` | **Required.** Your SGI's MAC address |
| `SGI_HOSTNAME` | `sgi` | Hostname for the SGI machine |
| `SGI_IP` | `172.16.42.2` | IP address to assign to SGI |
| `HOST_IP` | `172.16.42.1` | Laptop's IP on direct-cable interface |
| `HOST_INTERFACE` | `eth0` | Network interface connected to SGI |
| `NETWORK` | `172.16.42.0` | Network address |
| `NETMASK` | `255.255.255.0` | Network mask |
| `DOMAIN` | `local` | Domain name |
| `IRIX_VERSION` | `6.5.30` | IRIX version (sets boot image path) |

### Using a .env File

```bash
cp .env.example .env
nano .env  # Edit with your values
docker-compose up -d
```

### Using Command Line

```bash
SGI_MAC=08:00:69:0a:0b:0c HOST_INTERFACE=enp0s25 docker-compose up -d
```

## Media Fetch Script

The `fetch-media.sh` script downloads IRIX installation media from the SGI archive.

### Presets

| Preset | Contents | Size |
|--------|----------|------|
| `minimal` | Overlay disc1, Foundation disc1 | ~500 MB |
| `standard` | Overlay discs 1-3, apps, Foundation, NFS | ~2 GB |
| `full` | Standard + MIPSPro dev tools + extras | ~4 GB |

### Options

```bash
./fetch-media.sh [options]

Options:
  -v, --version   IRIX version: 6.5.30 (default), 6.5.22
  -p, --preset    Download preset: minimal, standard (default), full
  -m, --mirror    Mirror URL (default: https://sgi-irix.s3.amazonaws.com)
  -d, --dest      Destination directory (default: /srv/irix)
```

### Examples

```bash
# Standard 6.5.30 installation
./fetch-media.sh

# Minimal for quick testing
./fetch-media.sh -p minimal

# Full 6.5.22 with dev tools
./fetch-media.sh -v 6.5.22 -p full

# Custom destination
./fetch-media.sh -d /mnt/irix-media
```

## Helper Scripts

### Show Status
Display service health, configuration, and diagnostics:
```bash
./show-status.sh
```

Output includes:
- Container and process status
- Service health (DHCP, TFTP, RSH)
- Current configuration from environment
- IRIX media detection
- Host sysctl settings
- Recent log excerpts

### Tail Logs
Follow service logs in real-time:
```bash
./tail-logs.sh          # All logs
./tail-logs.sh dhcp     # DHCP only
./tail-logs.sh tftp     # TFTP only
./tail-logs.sh xinetd   # RSH/xinetd only
```

## Troubleshooting

### Monitor Network Traffic
```bash
# Watch DHCP/BOOTP
sudo tcpdump -i eth0 -n port 67 or port 68

# Watch TFTP
sudo tcpdump -i eth0 -n port 69

# Watch RSH
sudo tcpdump -i eth0 -n port 514
```

### Quick Diagnostics
```bash
# Check everything at once
./show-status.sh

# Follow logs while testing
./tail-logs.sh
```

### Common Issues

**SGI not getting IP address:**
- Check MAC address in `dhcpd.conf` matches SGI's `eaddr`
- Verify interface name in `default_isc-dhcp-server`
- Ensure ethernet cable is connected and link is up

**TFTP file not found:**
- Verify file exists: `ls -la /srv/irix/6.5.30/Overlay/disc1/stand/`
- Check TFTP root is `/srv/irix` not `/srv/tftp`

**RSH connection refused:**
- Check xinetd is running: `docker exec booterizer ps aux | grep xinetd`
- Verify `/etc/hosts.equiv` contains `+ +`

## Network Configuration

Default network: `172.16.42.0/24`
- Host (laptop): `172.16.42.1`
- SGI client: `172.16.42.2`

To use a different network, edit:
- `files/dhcpd.conf` - subnet and fixed-address
- `files/hosts` - IP mappings
- `setup-host.sh` invocation

## Services

| Service | Port | Purpose |
|---------|------|---------|
| DHCP/BOOTP | 67/udp | IP assignment, boot filename |
| TFTP | 69/udp | Boot image transfer |
| RSH | 514/tcp | `inst` file transfers |

## Files

```
docker/
├── Dockerfile              # Container image definition
├── docker-compose.yml      # Service configuration
├── entrypoint.sh           # Generates configs from env vars at startup
├── setup-host.sh           # Host network setup script
├── fetch-media.sh          # Download IRIX installation media
├── show-status.sh          # Display service status and diagnostics
├── tail-logs.sh            # Follow service logs
├── .env.example            # Example environment file (copy to .env)
├── README.md               # This file
└── files/
    ├── default_tftpd-hpa   # TFTP configuration (static)
    ├── supervisord.conf    # Process manager config (static)
    ├── xinetd.conf         # xinetd main config (static)
    └── xinetd.d/           # xinetd service definitions
        ├── rsh             # RSH service
        └── rlogin          # rlogin service
```

Note: DHCP, hosts, and RSH trust files are generated at container startup from environment variables.
