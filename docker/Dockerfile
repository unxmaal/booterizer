# Dockerfile for booterizer - IRIX network boot server
FROM debian:stable-slim

ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
#   isc-dhcp-server: BOOTP/DHCP for IP assignment and boot filename
#   tftpd-hpa: TFTP server for boot images
#   rsh-redone-server: RSH server for inst file transfers
#   xinetd: runs RSH as an inetd service
#   supervisor: process manager (no systemd in container)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        isc-dhcp-server \
        tftpd-hpa \
        rsh-redone-server \
        xinetd \
        supervisor \
        procps \
        net-tools && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create directories
RUN mkdir -p /srv/irix /var/log/supervisor /run/dhcp && \
    chmod 755 /srv/irix

# Copy configuration files
COPY files/dhcpd.conf /etc/dhcp/dhcpd.conf
COPY files/default_isc-dhcp-server /etc/default/isc-dhcp-server
COPY files/default_tftpd-hpa /etc/default/tftpd-hpa
COPY files/hosts.equiv /etc/hosts.equiv
COPY files/rhosts /srv/irix/.rhosts
COPY files/rhosts /root/.rhosts
COPY files/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# xinetd configuration for RSH
COPY files/xinetd.conf /etc/xinetd.conf
COPY files/xinetd.d/ /etc/xinetd.d/

# Ensure .rhosts permissions are correct (must be owned by root, not world-writable)
RUN chmod 600 /root/.rhosts /srv/irix/.rhosts

# Ports:
#   67/udp - DHCP server
#   69/udp - TFTP
#   512/tcp - rexec (not used but part of r-commands)
#   513/tcp - rlogin
#   514/tcp - rsh (shell)
EXPOSE 67/udp 69/udp 512/tcp 513/tcp 514/tcp

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
