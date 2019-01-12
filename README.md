booterizer
========

booterizer is designed to quickly configure a disposable VM to boot a specific version of the SGI IRIX installer over the network on an SGI machine without a whole lot of fuss. 

By default booterizer downloads IRIX 6.5.30 installation media from a mirror site. You can modify the media download URLs in the included Vagrantfile.

booterizer is not secure and may interfere with other network services (e.g. DHCP) so please don't leave it running long-term. I recommend only attaching the network interface to an isolated network for this purpose and then `vagrant halt` or `vagrant destroy` the VM when you are done installing.

The booterizer VM provides the following services:

* BOOTP server (via isc-dhcp)
* TFTP server (via tftpd-hpa)
* RSH server (via rsh-server)

NOTE: This fork no longer supports CD images. It may again in the future, if there is demand. If you must extract from CD media, see the original project at https://github.com/halfmanhalftaco/irixboot. 

## Requirements

* [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
* [Vagrant](https://www.vagrantup.com/downloads.html)
	* vagrant plugin install vagrant-guest_ansible
* VM host with TWO network interfaces
  * I very much recommend using a host with two built-in interfaces, such as one WiFi and one Ethernet


I am not sure what range of IRIX versions this will work with or what SGI machines are compatible. Personal testing and user reports show the following (at minimum) should be compatible:

* Target Hardware
	* SGI O2
	* SGI Indigo
	* SGI Indigo2
	* SGI Octane

* Operating Systems
	* IRIX 6.5.22
	* IRIX 6.5.30

I suspect that most other hardware and OS versions released in those timeframes will also work (e.g. O2, server variants, etc.) SGI obviously kept the netboot/install process pretty consistent so I'd expect it to work on probably any MIPS-based SGI system. 

(feel free to send me a Personal IRIS or Tezro or something to test it on!)

Some changes will definitely be needed to support other hypervisors, but booterizer should work with VirtualBox on other systems as long as the `bridgenic` parameter is updated correctly. 

## Setup
By default, this vagrant VM will fetch proper 6.5.30 installation packages from ftp.irisware.net.


## Settings

These settings are found at the top of `Vagrantfile`. Edit them to suit your environment.

Set this to the version of IRIX you are installing. You must create a subdirectory in the `irix` directory with the same name:
```
irixversion = '6.5'
```

Currently installmethod is only ftp. cd is no longer supported on this fork.
```
installmethod = "ftp"
```

Pick your install mirror
```
installmirror = "ftp.irisware.com"
```

your SGI box's hostname
```
clientname = 'sgi'
```

whatever domain that you make up
```
clientdomain = 'devonshire.local'
```

Internal network your SGI will be on. Note this is the actual "network", in the technical subnetting sense of the term.
```
network = '192.168.0.0' 
```

Internal network's netmask
```
netmask = '255.255.255.0'
```

booterizer's host IP. This is the VM's IP on its internal point to point link to the target SGI client machine.
```
hostip = '192.168.0.1'
```

The SGI client box's IP address
```
clientip = '192.168.0.2'
```

The sgi box's physical hardware address, from printenv at PROM
```
clientether = '08:00:69:0e:af:65'
```

This is the name of the interface on your physical machine that's connected to your SGI box. In my case, it's the ethernet adapter, which is en0. 
```
bridgenic = 'en0'
```

## Networking overview
The booterizer vm's fake network interfaces map to your physical host as follows:
| Physical Host | booterizer |
|---|---|
| Home LAN-connected NIC | Adapter 1, NAT, eth0 |
| SGI-connected NIC | Adapter 2, Bridged, eth1 |

NOTE: This VM starts a BOOTP server that will listen to broadcast traffic on your network. It is configured to ignore anything but the target system but if you have another DHCP/BOOTP server on the LAN segment the queries from the SGI hardware may get answered by your network's existing DHCP server which will cause problems. You may want to temporarily disable DHCP/BOOTP if you are running it on your LAN, configure it to not reply to queries from the SGI system, or put SGI hardware on a separate LAN (my recommendation).

## IRIX media from FTP
This VM can now sync installation media from the FTP site ftp.irisware.net. As this site contains more, and more recently updated, packages, it is the default. 

Vagrant will automatically create a vagrant/irix directory on your host machine that is shared between it and the VM. It will then fetch the installation media archives only if they are missing from that directory. 

## Booting

###### caveat: I am not an SGI expert by any means, this is just based on my experience as to what works.

### fx (Partitioner)

If you need to boot `fx` to label/partition your disk, open the command monitor and issue a command similar to this:

`bootp():/disc1/stand/fx.ARCS`

where `/disc1/stand/fx.ARCS` is a path relative to your selected IRIX version in the directory structure from above. When installing IRIX 6.5.x you'll want to use the partitioner included with the overlay set (first disc), but prior versions of IRIX usually locate the partitioner on the first install disc.

 Use `fx.ARCS` for R4xxx machines (like the O2) and `fx.64` for R5000+ machines (and others for older machines, I assume). Once `booterizer` finishes setup it lists any detected partitioners to help you find the correct path.

### inst (IRIX installer)
NOTE: After `booterizer` initializes, it displays a list of all `dist` subdirectories for your convenience. Use this list to preserve your sanity while running inst.

The installer can be reached through the monitor GUI as follows:

* At the maintenance boot screen, select "Install Software"
* If it prompts you for an IP address, enter the same address you entered into the Vagrantfile config for `clientip`.
* Use `booterizer` as the install server hostname.
* For the installation path, this depends on your directory structure. If you use the structure example from above, you would use the path `disc1/dist`. Notice the lack of leading `/`.
* This should load the miniroot over the network and boot into the installer.
* To access the other distributions you extracted, use `open booterizer:<directory>/dist`.

# Provisioning your IRIX host with irix_ansible
https://github.com/unxmaal/irix_ansible/

booterizer automatically installs irix_ansible, which allows for easy configuration of your IRIX system.

irix_ansible performs the following tasks, and more:
  * install wget, python, and openssh
  * start sshd
  * installs nekodeps
  * installs base packages
  * performs security hardening

irix_ansible should be run immediately after your IRIX host has been installed, and has booted for the first time:
* Connect your IRIX host to your home LAN
* vagrant ssh
* sudo -i
* ifdown eth0 (this disables the point to point link originally used by booterizer)
* Follow the irix_ansible README to create your own ansible vault
  * group_vars/default/vault.yml
* Place your vault password in /home/vagrant/.vault_pass.txt
* Continue with the irix_ansible README



## PRO TIP
Take a look in the expect/ directory for my own personal install scripts, written in expect. You can use them as a guide for what to select during an installation -- or if you're really brave/foolish, follow the enclosed README to run those scripts over serial console.

## License

MIT License

Portions of this project are:
Copyright (c) 2018 Andrew Liles
Copyright (c) 2018 Eric Dodd

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
