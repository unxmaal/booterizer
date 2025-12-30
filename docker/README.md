# Booterizer Docker

Network boot server for installing IRIX on SGI hardware via direct ethernet cable.

## Quick Start

### 1. Configure Your SGI's MAC Address

Find your SGI's MAC address from the PROM:
```
printenv eaddr
```

Edit `files/dhcpd.conf` and update the `hardware ethernet` line:
```
host sgi {
  hardware ethernet 08:00:69:xx:xx:xx;  # <-- Your SGI's MAC
  ...
}
```

### 2. Configure Your Network Interface

Edit `files/default_isc-dhcp-server` with your interface name:
```bash
# Find your ethernet interface name
ip link show

# Edit the file
INTERFACESv4="eth0"  # or enp0s25, eno1, etc.
```

### 3. Set Up Host Networking

```bash
# Configure interface and apply sysctl settings
sudo ./setup-host.sh eth0 192.168.42.1
```

### 4. Populate IRIX Media

Place your IRIX installation files in `/srv/irix` on the host with this structure:
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

### 5. Start the Container

```bash
docker-compose build
docker-compose up -d
```

### 6. Boot Your SGI

On the SGI PROM:
```
setenv netaddr 192.168.42.2
bootp():/6.5.30/Overlay/disc1/stand/fx.64
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

### View Container Logs
```bash
docker-compose logs -f
```

### Check Service Status
```bash
docker exec booterizer ps aux
docker exec booterizer cat /var/log/supervisor/dhcpd.log
docker exec booterizer cat /var/log/supervisor/tftpd.log
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

Default network: `192.168.42.0/24`
- Host (laptop): `192.168.42.1`
- SGI client: `192.168.42.2`

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
├── setup-host.sh           # Host network setup script
├── README.md               # This file
└── files/
    ├── dhcpd.conf          # DHCP configuration (edit for your SGI)
    ├── default_isc-dhcp-server  # DHCP interface binding
    ├── default_tftpd-hpa   # TFTP configuration
    ├── hosts               # Hostname mappings
    ├── hosts.equiv         # RSH trust (system-wide)
    ├── rhosts              # RSH trust (user-level)
    ├── supervisord.conf    # Process manager config
    ├── xinetd.conf         # xinetd main config
    └── xinetd.d/           # xinetd service definitions
        ├── rsh             # RSH service
        └── rlogin          # rlogin service
```
