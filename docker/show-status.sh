#!/bin/bash
# show-status.sh - Display booterizer service status and configuration
#
# Usage: ./show-status.sh

CONTAINER="booterizer"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

header() { echo -e "\n${BLUE}=== $1 ===${NC}"; }
ok() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
err() { echo -e "${RED}[ERR]${NC} $1"; }

# Check if container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
    err "Container '$CONTAINER' is not running"
    echo ""
    echo "Start it with: docker-compose up -d"
    exit 1
fi

header "Container Status"
docker ps --filter "name=${CONTAINER}" --format "table {{.Status}}\t{{.Ports}}"

header "Process Status"
docker exec "$CONTAINER" ps aux --forest 2>/dev/null | grep -E "(PID|supervisor|dhcpd|tftpd|xinetd)" || \
    docker exec "$CONTAINER" ps aux | head -20

header "Service Health"

# Check DHCP
if docker exec "$CONTAINER" pgrep -x dhcpd >/dev/null 2>&1; then
    ok "DHCP server (dhcpd) is running"
else
    err "DHCP server (dhcpd) is NOT running"
fi

# Check TFTP
if docker exec "$CONTAINER" pgrep -f "in.tftpd" >/dev/null 2>&1; then
    ok "TFTP server (tftpd) is running"
else
    err "TFTP server (tftpd) is NOT running"
fi

# Check xinetd (for RSH)
if docker exec "$CONTAINER" pgrep -x xinetd >/dev/null 2>&1; then
    ok "xinetd (RSH) is running"
else
    err "xinetd (RSH) is NOT running"
fi

header "Network Configuration"
echo "From container environment:"
docker exec "$CONTAINER" sh -c 'echo "  SGI_MAC:        $SGI_MAC"'
docker exec "$CONTAINER" sh -c 'echo "  SGI_IP:         $SGI_IP"'
docker exec "$CONTAINER" sh -c 'echo "  SGI_HOSTNAME:   $SGI_HOSTNAME"'
docker exec "$CONTAINER" sh -c 'echo "  HOST_IP:        $HOST_IP"'
docker exec "$CONTAINER" sh -c 'echo "  HOST_INTERFACE: $HOST_INTERFACE"'
docker exec "$CONTAINER" sh -c 'echo "  IRIX_VERSION:   $IRIX_VERSION"'

header "DHCP Configuration"
docker exec "$CONTAINER" cat /etc/dhcp/dhcpd.conf 2>/dev/null | grep -E "(hardware ethernet|fixed-address|filename)" | sed 's/^/  /'

header "IRIX Media"
DIST_COUNT=$(docker exec "$CONTAINER" find /srv/irix -type d -name "dist" 2>/dev/null | wc -l)
if [[ "$DIST_COUNT" -gt 0 ]]; then
    ok "Found $DIST_COUNT dist directories in /srv/irix"
    echo "  Boot images:"
    docker exec "$CONTAINER" ls -la /srv/irix/*/Overlay/disc1/stand/fx* 2>/dev/null | sed 's/^/    /' || \
        warn "  No fx.* boot images found"
else
    warn "No dist directories found in /srv/irix"
    echo "  Make sure IRIX media is mounted/copied to /srv/irix on the host"
fi

header "Selections File"
if docker exec "$CONTAINER" test -f /srv/irix/selections 2>/dev/null; then
    SELECTION_COUNT=$(docker exec "$CONTAINER" grep -c "^from" /srv/irix/selections 2>/dev/null || echo 0)
    ok "selections file exists with $SELECTION_COUNT sources"
else
    warn "selections file not found (will be created on container restart)"
fi

header "Host sysctl Settings"
if [[ -f /proc/sys/net/ipv4/ip_no_pmtu_disc ]]; then
    PMTU=$(cat /proc/sys/net/ipv4/ip_no_pmtu_disc)
    if [[ "$PMTU" == "1" ]]; then
        ok "ip_no_pmtu_disc = 1 (PMTU discovery disabled)"
    else
        err "ip_no_pmtu_disc = $PMTU (should be 1 for SGI compatibility)"
        echo "  Run: sudo ./setup-host.sh <interface>"
    fi
else
    warn "Cannot read sysctl values"
fi

header "Recent Logs (last 5 lines each)"
echo -e "${YELLOW}DHCP:${NC}"
docker exec "$CONTAINER" tail -5 /var/log/supervisor/dhcpd.log 2>/dev/null | sed 's/^/  /' || echo "  (no logs)"
echo -e "${YELLOW}TFTP:${NC}"
docker exec "$CONTAINER" tail -5 /var/log/supervisor/tftpd.log 2>/dev/null | sed 's/^/  /' || echo "  (no logs)"
echo -e "${YELLOW}xinetd:${NC}"
docker exec "$CONTAINER" tail -5 /var/log/supervisor/xinetd.log 2>/dev/null | sed 's/^/  /' || echo "  (no logs)"

echo ""
echo "For live logs, run: ./tail-logs.sh"
echo "To monitor network: sudo tcpdump -i <interface> -n port 67 or port 68 or port 69"
