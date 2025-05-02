#!/bin/bash
set -e

CONTAINER_NAME=booterizer
CONTAINER_PATH=/var/lib/machines/$CONTAINER_NAME
DEBIAN_VERSION=stable
MIRROR_URL=http://deb.debian.org/debian

# setup
sudo add-apt-repository ppa:rmescandon/yq
sudo apt update 
sudo apt install -y yq debootstrap

# Create the container rootfs
if [ ! -d "$CONTAINER_PATH" ]; then
  echo "Creating container rootfs with debootstrap..."
  sudo debootstrap --arch=amd64 --include=dbus,rsh-server,dnsmasq,mksh,xfsprogs,rsync,tcpdump,git,curl $DEBIAN_VERSION "$CONTAINER_PATH" "$MIRROR_URL"

else
  echo "Container rootfs already exists. Skipping debootstrap."
fi

# Copy .nspawn config
echo "Copying container config..."
sudo mkdir -p /etc/systemd/nspawn
sudo cp nspawn/booterizer.nspawn /etc/systemd/nspawn/booterizer.nspawn

# Inject static network config into container
echo "Injecting host0 and enp0s25 network configs..."
sudo mkdir -p "${CONTAINER_PATH}/etc/systemd/network"
sudo cp nspawn/50-host0.network "${CONTAINER_PATH}/etc/systemd/network/50-host0.network"
sudo cp nspawn/50-enp0s25.network "${CONTAINER_PATH}/etc/systemd/network/50-enp0s25.network"
sudo cp -Ra booterizer_sysd_files/etc/* ${CONTAINER_PATH}/etc/. 

# Enable systemd-networkd inside container
if ! sudo test -L "$CONTAINER_PATH/etc/systemd/system/multi-user.target.wants/systemd-networkd.service"; then
  echo "Enabling systemd-networkd inside container..."
  sudo ln -s /lib/systemd/system/systemd-networkd.service \
    "$CONTAINER_PATH/etc/systemd/system/multi-user.target.wants/systemd-networkd.service"
fi

# Enable container to start at boot
sudo systemctl enable systemd-nspawn@"$CONTAINER_NAME"

# Start container
sudo systemctl start systemd-nspawn@"$CONTAINER_NAME"
echo "Booterizer container started."

# Set up NAT for container veth (must happen after container starts)
VETH_NAME=$(ip link show | grep -o 've-[^:@]*' | grep "$CONTAINER_NAME" | head -n1)

if [ -n "$VETH_NAME" ]; then
  echo "Configuring NAT for $VETH_NAME"
  sudo ip addr add 10.10.10.1/24 dev "$VETH_NAME" || true
  sudo ip link set "$VETH_NAME" up
  sudo sysctl -w net.ipv4.ip_forward=1
  sudo iptables -t nat -C POSTROUTING -s 10.10.10.0/24 -o wlp3s0 -j MASQUERADE 2>/dev/null \
    || sudo iptables -t nat -A POSTROUTING -s 10.10.10.0/24 -o wlp3s0 -j MASQUERADE
else
  echo "WARNING: veth interface for $CONTAINER_NAME not found. NAT not configured."
fi
