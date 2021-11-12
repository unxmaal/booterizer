#!/usr/bin/bash

echo "Clearing shell history."
rm -f /home/pi/.bash_history
rm -f /root/.bash_history

echo "Clearing wifi config."
cat << EOF > /etc/wpa_supplicant/wpa_supplicant.conf
country=US
update_config=1
ctrl_interface=/var/run/wpa_supplicant

network={
  scan_ssid=1
  ssid="CHANGEME"
  psk="CHANGEME"
}
EOF

echo "Cleaning apt caches."
apt-get clean -y
apt-get autoclean -y

echo "Zeroing free space. This will take a while."
dd if=/dev/zero of=/EMPTY bs=1M 
rm -f /EMPTY
echo "Run 'halt -p'."

