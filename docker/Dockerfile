# Dockerfile
FROM debian:stable-slim

ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        isc-dhcp-server \
        tftpd-hpa \
        rsh-server \
        mksh \
        xfsprogs \
        supervisor && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy configuration files
COPY files/dhcpd.conf /etc/dhcp/dhcpd.conf
COPY files/default_isc-dhcp-server /etc/default/isc-dhcp-server
COPY files/default_tftpd-hpa /etc/default/tftpd-hpa
COPY files/hosts /etc/hosts
COPY files/hosts.equiv /etc/hosts.equiv
COPY files/rhosts /srv/irix/.rhosts
COPY files/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Create TFTP root directory
RUN mkdir -p /srv/tftp && chmod 777 /srv/tftp

EXPOSE 67/udp 69/udp 512/tcp 514/tcp

CMD ["/usr/bin/supervisord"]
