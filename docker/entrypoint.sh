#!/bin/bash
# entrypoint.sh - Generate configuration files from environment variables
#
# This script runs at container startup to generate config files
# based on environment variables, then starts supervisord.

set -e

# Default values
: "${SGI_HOSTNAME:=sgi}"
: "${SGI_IP:=172.16.42.2}"
: "${SGI_MAC:=08:00:69:00:00:00}"
: "${HOST_IP:=172.16.42.1}"
: "${HOST_INTERFACE:=eth0}"
: "${NETMASK:=255.255.255.0}"
: "${NETWORK:=172.16.42.0}"
: "${DOMAIN:=local}"
: "${IRIX_VERSION:=6.5.30}"

# Derive additional values
BOOTERIZER_HOSTNAME="booterizer"

echo "========================================"
echo "Booterizer Configuration"
echo "========================================"
echo "SGI_HOSTNAME:    $SGI_HOSTNAME"
echo "SGI_IP:          $SGI_IP"
echo "SGI_MAC:         $SGI_MAC"
echo "HOST_IP:         $HOST_IP"
echo "HOST_INTERFACE:  $HOST_INTERFACE"
echo "NETWORK:         $NETWORK"
echo "NETMASK:         $NETMASK"
echo "DOMAIN:          $DOMAIN"
echo "IRIX_VERSION:    $IRIX_VERSION"
echo "========================================"

# Validate required values
if [[ "$SGI_MAC" == "08:00:69:00:00:00" ]]; then
    echo ""
    echo "WARNING: Using default MAC address!"
    echo "Set SGI_MAC to your SGI's actual MAC address."
    echo "Find it on SGI PROM with: printenv eaddr"
    echo ""
fi

# Generate /etc/dhcp/dhcpd.conf
echo "Generating dhcpd.conf..."
cat > /etc/dhcp/dhcpd.conf << EOF
# DHCP/BOOTP configuration for booterizer
# Auto-generated from environment variables

allow booting;
allow bootp;

subnet ${NETWORK} netmask ${NETMASK} {
  ignore unknown-clients;
}

host ${SGI_HOSTNAME} {
  hardware ethernet ${SGI_MAC};
  fixed-address ${SGI_IP};
  option domain-name-servers ${HOST_IP};
  option domain-name "${DOMAIN}";
  filename "${IRIX_VERSION}/Overlay/disc1/stand/fx.64";
}
EOF

# Generate /etc/default/isc-dhcp-server
echo "Generating isc-dhcp-server defaults..."
cat > /etc/default/isc-dhcp-server << EOF
# Auto-generated from environment variables
INTERFACESv4="${HOST_INTERFACE}"
EOF

# Generate /etc/hosts
echo "Generating /etc/hosts..."
cat > /etc/hosts << EOF
# Auto-generated from environment variables
127.0.0.1	localhost
${HOST_IP}	${BOOTERIZER_HOSTNAME}.${DOMAIN}	${BOOTERIZER_HOSTNAME}
${SGI_IP}	${SGI_HOSTNAME}.${DOMAIN}	${SGI_HOSTNAME}
EOF

# Generate /etc/hosts.equiv
echo "Generating /etc/hosts.equiv..."
cat > /etc/hosts.equiv << EOF
# RSH trust - intentionally permissive for isolated network
${SGI_HOSTNAME}.${DOMAIN}
${SGI_HOSTNAME}
${SGI_IP}
+ +
EOF

# Generate .rhosts files
echo "Generating .rhosts files..."
cat > /root/.rhosts << EOF
# RSH trust - intentionally permissive for isolated network
${SGI_HOSTNAME}.${DOMAIN} root
${SGI_HOSTNAME}.${DOMAIN} guest
${SGI_HOSTNAME} root
${SGI_HOSTNAME} guest
${SGI_IP} root
${SGI_IP} guest
+ +
EOF
chmod 600 /root/.rhosts

# Copy to /srv/irix for guest access
cp /root/.rhosts /srv/irix/.rhosts 2>/dev/null || true
chmod 600 /srv/irix/.rhosts 2>/dev/null || true

# Generate selections file if dist directories exist
SELECTIONS_FILE="/srv/irix/selections"
if [[ -d /srv/irix ]]; then
    echo "Generating selections file..."
    echo "# Auto-generated list of installation sources" > "$SELECTIONS_FILE"
    echo "# Load in inst with: Admin > load ${BOOTERIZER_HOSTNAME}:selections" >> "$SELECTIONS_FILE"
    echo "" >> "$SELECTIONS_FILE"

    # Find all dist directories
    find /srv/irix -type d -name "dist" 2>/dev/null | sort | while read -r distdir; do
        # Convert to relative path from /srv/irix
        relpath="${distdir#/srv/irix/}"
        echo "from ${BOOTERIZER_HOSTNAME}:/${relpath}" >> "$SELECTIONS_FILE"
    done

    echo "Found $(grep -c '^from' "$SELECTIONS_FILE" 2>/dev/null || echo 0) dist directories"
fi

# Generate commands file for automated installation
COMMANDS_FILE="/srv/irix/commands"
echo "Generating commands file..."
cat > "$COMMANDS_FILE" << 'EOF'
# Automated inst commands
# Source in inst with: Admin > source booterizer:commands
return
keep *
install standard
keep incompleteoverlays
conflicts
go
EOF

# Ensure proper permissions
chmod 644 "$SELECTIONS_FILE" 2>/dev/null || true
chmod 644 "$COMMANDS_FILE" 2>/dev/null || true

echo ""
echo "Configuration complete. Starting services..."
echo ""

# Start supervisord
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
