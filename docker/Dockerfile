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

COPY files/rhosts /srv/irix/.rhosts
RUN useradd -m -s /bin/ksh -d /srv/irix -u 1004 guest && \
    chown -R guest:guest /srv/irix && \
    chown guest:guest /srv/irix/.rhosts && \
    chmod 600 /srv/irix/.rhosts


# temp install extra crap
RUN apt-get update && apt-get install -y \
  iproute2 \
  net-tools \
  inetutils-ping \
  systemctl \
  rsyslog \
  bash \
  isc-dhcp-server \
  tftpd-hpa \
  rsh-server \
  mksh \
  xfsprogs

RUN mkdir -p /var/lib/dhcp && touch /var/lib/dhcp/dhcpd.leases
RUN mkdir -p /var/log && touch /var/log/syslog
RUN systemctl enable rsyslog


# Copy configuration files
COPY files/dhcpd.conf /etc/dhcp/dhcpd.conf
COPY files/default_isc-dhcp-server /etc/default/isc-dhcp-server
COPY files/default_tftpd-hpa /etc/default/tftpd-hpa
COPY files/hosts.equiv /etc/hosts.equiv
COPY files/rhosts /srv/irix/.rhosts
COPY files/inetd.conf /etc/inetd.conf
COPY files/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY files/hosts /etc/hosts

# Create TFTP root directory
#RUN mkdir -p /srv/tftp && chmod 777 /srv/tftp

EXPOSE 67/udp 69/udp 512/tcp 514/tcp

CMD ["/usr/bin/supervisord"]
