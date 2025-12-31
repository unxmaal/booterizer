#!/bin/bash
# setup-host.sh - Configure host system for booterizer
#
# This script configures the Linux host (laptop) for direct-cable
# connection to SGI hardware. Must be run with sudo.
#
# Usage: sudo ./setup-host.sh <interface> [host_ip]
#
# Example: sudo ./setup-host.sh eth0 192.168.42.1

set -e

INTERFACE="${1:-}"
HOST_IP="${2:-172.16.42.1}"
NETMASK="255.255.255.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check for root
if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root (use sudo)"
    exit 1
fi

# Check for interface argument
if [[ -z "$INTERFACE" ]]; then
    log_error "Usage: $0 <interface> [host_ip]"
    echo ""
    echo "Available interfaces:"
    ip -o link show | awk -F': ' '{print "  " $2}'
    exit 1
fi

# Verify interface exists
if ! ip link show "$INTERFACE" &>/dev/null; then
    log_error "Interface '$INTERFACE' not found"
    echo ""
    echo "Available interfaces:"
    ip -o link show | awk -F': ' '{print "  " $2}'
    exit 1
fi

log_info "Configuring booterizer host..."
log_info "  Interface: $INTERFACE"
log_info "  Host IP:   $HOST_IP"
log_info "  Netmask:   $NETMASK"
echo ""

# Step 1: Apply sysctl settings (critical for SGI IP stack compatibility)
log_info "Applying sysctl settings for SGI compatibility..."

# Disable PMTU discovery - SGI systems can't handle it
sysctl -w net.ipv4.ip_no_pmtu_disc=1

# Adjust port range for RSH
sysctl -w net.ipv4.ip_local_port_range="2048 32767"

# Make settings persistent
SYSCTL_CONF="/etc/sysctl.d/99-booterizer.conf"
cat > "$SYSCTL_CONF" << EOF
# Booterizer settings for SGI hardware compatibility
# Disable PMTU discovery (SGI IP stacks can't handle it)
net.ipv4.ip_no_pmtu_disc=1
# Port range for RSH connections
net.ipv4.ip_local_port_range=2048 32767
EOF
log_info "Saved persistent sysctl config to $SYSCTL_CONF"

# Step 2: Configure network interface
log_info "Configuring network interface $INTERFACE..."

# Bring interface down first
ip link set "$INTERFACE" down 2>/dev/null || true

# Flush existing addresses
ip addr flush dev "$INTERFACE" 2>/dev/null || true

# Set static IP
ip addr add "${HOST_IP}/${NETMASK}" dev "$INTERFACE"

# Bring interface up
ip link set "$INTERFACE" up

# Step 3: Stop NetworkManager from managing this interface (if NM is running)
if systemctl is-active --quiet NetworkManager 2>/dev/null; then
    log_warn "NetworkManager is running. Consider adding $INTERFACE to unmanaged devices."
    log_warn "Add to /etc/NetworkManager/conf.d/booterizer.conf:"
    echo "    [keyfile]"
    echo "    unmanaged-devices=interface-name:$INTERFACE"
fi

# Step 4: Verify configuration
echo ""
log_info "Verifying configuration..."
echo ""
echo "Interface status:"
ip addr show "$INTERFACE"
echo ""
echo "sysctl values:"
echo "  ip_no_pmtu_disc = $(cat /proc/sys/net/ipv4/ip_no_pmtu_disc)"
echo "  ip_local_port_range = $(cat /proc/sys/net/ipv4/ip_local_port_range)"
echo ""

log_info "Host configuration complete!"
echo ""
echo "Next steps:"
echo "  1. Connect ethernet cable between laptop and SGI"
echo "  2. Start the container: docker-compose up -d"
echo "  3. On SGI PROM:"
echo "       setenv netaddr 192.168.42.2"
echo "       bootp():/6.5.30/Overlay/disc1/stand/fx.64"
echo ""
echo "To monitor traffic:"
echo "  tcpdump -i $INTERFACE -n port 67 or port 68 or port 69"
