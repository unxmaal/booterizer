# Dockerfile for booterizer - IRIX network boot server
# Using Bullseye (oldstable) because rsh-server was removed from Bookworm
FROM debian:bullseye-slim

ENV DEBIAN_FRONTEND=noninteractive

# Default environment variables (can be overridden at runtime)
# Using 172.16.42.0/24 to avoid conflicts with common home networks (192.168.x.x, 10.x.x.x)
ENV SGI_HOSTNAME=sgi \
    SGI_IP=172.16.42.2 \
    SGI_MAC=08:00:69:00:00:00 \
    HOST_IP=172.16.42.1 \
    HOST_INTERFACE=eth0 \
    NETMASK=255.255.255.0 \
    NETWORK=172.16.42.0 \
    DOMAIN=local \
    IRIX_VERSION=6.5.30

# Install required packages
#   isc-dhcp-server: BOOTP/DHCP for IP assignment and boot filename
#   tftpd-hpa: TFTP server for boot images
#   rsh-server: RSH server for inst file transfers (provides in.rshd, in.rlogind)
#   update-inetd: required by rsh-server postinst
#   xinetd: runs RSH as an inetd service
#   supervisor: process manager (no systemd in container)
#   findutils: for generating selections file
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        isc-dhcp-server \
        tftpd-hpa \
        update-inetd \
        rsh-server \
        xinetd \
        supervisor \
        procps \
        net-tools \
        findutils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create directories
RUN mkdir -p /srv/irix /var/log/supervisor /run/dhcp && \
    chmod 755 /srv/irix

# Copy static configuration files (not templated)
COPY files/default_tftpd-hpa /etc/default/tftpd-hpa
COPY files/hosts.equiv /etc/hosts.equiv
COPY files/rhosts /srv/irix/.rhosts
COPY files/inetd.conf /etc/inetd.conf
COPY files/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY files/hosts /etc/hosts

# xinetd configuration for RSH (static)
COPY files/xinetd.conf /etc/xinetd.conf
COPY files/xinetd.d/ /etc/xinetd.d/

# Copy entrypoint script (generates dynamic configs from env vars)
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Ports:
#   67/udp - DHCP server
#   69/udp - TFTP
#   512/tcp - rexec (not used but part of r-commands)
#   513/tcp - rlogin
#   514/tcp - rsh (shell)
EXPOSE 67/udp 69/udp 512/tcp 513/tcp 514/tcp

ENTRYPOINT ["/entrypoint.sh"]
