booterizer
========

booterizer is designed to quickly configure a disposable VM to boot a specific version of the SGI IRIX installer over the network on an SGI machine without a whole lot of fuss. 

By default booterizer downloads IRIX 6.5.30 installation media from a mirror site. You can modify the media download URLs in the included Vagrantfile.

booterizer also works with IRIX 6.5.22 for older SGI systems that can run 6.5
booterizer even works with IRIX 5.3 for classic SGI systems that cannot run 6.5.x


booterizer is not secure and may interfere with other network services (e.g. DHCP) so please don't leave it running long-term. I recommend only attaching the network interface to an isolated network for this purpose and then `vagrant halt` or `vagrant destroy` the VM when you are done installing.

The booterizer VM provides the following services:

* BOOTP server (via isc-dhcp)
* TFTP server (via tftpd-hpa)
* RSH server (via rsh-server)

NOTE: This fork no longer supports CD images. It may again in the future, if there is demand. If you must extract from CD media, see the original project at https://github.com/halfmanhalftaco/irixboot. 

# Where to get help
* Create a Github Issue vs this project
* SGIDev Discord: https://discord.gg/p2zZ7TZ


# Requirements

* [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
* [Vagrant](https://www.vagrantup.com/downloads.html)
	* vagrant plugin install vagrant-guest_ansible
* VM host with TWO network interfaces
  * I very much recommend using a host with two built-in interfaces, such as one WiFi and one Ethernet


## Installation of Prerequisite sofware for OSX (Host)
* Apple OSX has Brew - which can install Vagrant and VirtualBox for you from the command line with one command.
* Install Brew following directions at their website here: https://brew.sh/

* If you have brew installed you can install Vagrant and VB:
```
$  brew cask install vagrant
$  brew cask install virtualbox
```

## Installation of Prerequisite sofware for Ubuntu (Host)
* Installing recent vagrant must be done manually on older versions of ubuntu, the procedure below will validate the package using its checksums. Justing using apt-get will install an older version we don't want to use.
* We need to install virtualbox (to run the virtual linux server for the SGI installation media)
* We need to install vagrant 2.2.3 to configure and kick of provisioning of the new VM
* We need to install ansible to provision the new VM

```
$  sudo apt-get install virtualbox

$ wget -c https://releases.hashicorp.com/vagrant/2.2.3/vagrant_2.2.3_x86_64.deb
$ wget -c https://releases.hashicorp.com/vagrant/2.2.3/vagrant_2.2.3_SHA256SUMS
$ wget -c https://releases.hashicorp.com/vagrant/2.2.3/vagrant_2.2.3_SHA256SUMS.sig
$ gpg --verify vagrant_2.2.3_SHA256SUMS.sig vagrant_2.2.3_SHA256SUMS
$ shasum -a 256 -c <(cat vagrant_2.2.3_SHA256SUMS | grep 64.deb) -s
$ sudo dpkg -i vagrant_2.2.3_x86_64.deb
$ rm vagrant_2.2.3*

$ sudo apt-add-repository ppa:ansible/ansible
$ sudo apt update && sudo apt install ansible -y

```
Now you have vagrant 2.2.3 installed on an older Ubuntu system.


## Verify Versions
Verify your installed versions:
```
vagrant -v
ansible --version
```
You should have:
* ansible 2.7.6
* Vagrant 2.2.3

Having an exact version of VirtualBox is not critical- as long as you have the proper version of Vagrant, it will run VirtualBox for you.


## Vagrant Plugins
* Whichever host os (OSX or Linux) you are using, install the vagrant plugin with this command:

```
$ vagrant plugin install vagrant-vbguest
```
This will install a plugin that will automatically update any VirtualBox VMs with the latest guest additions

Now we can move on and start to configure the Vagrant file and start up the VM...


# Target SGI Systems

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

Some changes will definitely be needed to support other hypervisors, but booterizer should work with VirtualBox on other systems as long as the `bridgenic` parameter is updated correctly. 


# Setup
By default, this vagrant VM will fetch proper irix installation packages from ftp.irisware.net (or another mirror).

## Settings
These settings are found in `settings.yml`. Edit them to suit your environment.

* Edit these lines

Set this to the version of IRIX you are installing.
```
irixversion: "6.5.30"
```

Currently installmethod is only ftp/http. Choose ftp here and http will be used if available. cd is no longer supported.
```
installmethod: "ftp"
```

Pick your install mirror
 * the same files are in both locations
 * choose only one of these
```
  installmirror: "http://us.irisware.net/sgi-irix"
  installmirror: "http://sgi-irix.s3-website-us-east-1.amazonaws.com"
```

This is the new hostname for your SGI post-installation
```
clientname: 'sgi'
```

Whatever domain you use at home, or make one up for the install
```
clientdomain: 'devonshire.local'
```

Internal network your SGI will be on. Note this is the actual "network", in the technical subnetting sense of the term.
```
network: '192.168.0.0' 
```

Internal network's netmask
```
netmask: '255.255.255.0'
```

booterizer's host IP. This is the VM's IP on its internal point to point link to the target SGI client machine.
* this will be a unique, unused ip address in the subnet that your home/office router has created
```
hostip: '192.168.0.40'
```

The SGI client box's IP address
* this will be a unique, unused ip address in the subnet that your home/office router has created
* it cannot be the same as the Host IP above.
```
clientip: '192.168.0.41'
```

The sgi box's physical hardware address, from printenv at PROM
* older PROMs use the command: eaddr to obtain this
```
clientether: '08:00:69:0e:af:65'
```

This is the name of the interface on your physical machine that's connected to your SGI box. In my case, it's the ethernet adapter, which is en0.
* linux would usually be eth0, a Macintosh will use en0
```
bridgenic: 'en0'
```

## Networking overview
The booterizer vm's fake network interfaces map to your physical host as follows:
| Physical Host | booterizer |
|---|---|
| Home LAN-connected NIC | Adapter 1, NAT, eth0 |
| SGI-connected NIC | Adapter 2, Bridged, eth1 |

NOTE: This VM starts a BOOTP server that will listen to broadcast traffic on your network. It is configured to ignore anything but the target system but if you have another DHCP/BOOTP server on the LAN segment the queries from the SGI hardware may get answered by your network's existing DHCP server which will cause problems. You may want to temporarily disable DHCP/BOOTP if you are running it on your LAN, configure it to not reply to queries from the SGI system, or put SGI hardware on a separate LAN (my recommendation).

### One possible setup
![Image of a possible network setup for Booterizer](docs/booterizer_network_v1a.png?raw=true "Booterizer Network Setup")


## IRIX media from FTP or S3
This VM can now sync installation media from the FTP site ftp.irisware.net or from S3 using http. Irisware it is the default but you can easily change this to S3 by editing the settings.yml file to:
```
installmirror:  "https://s3.amazonaws.com"
```
and then saving the file and using the vagrant provision command if the vagrant host has been booted.

Vagrant will automatically create a vagrant/irix directory on your host machine that is shared between it and the VM. It will then fetch the installation media archives only if they are missing from that directory. 

# Booting

## Set IP address in PROM

When the PROM menu appears choose: Enter Command Monitor

* Set the netaddr of your SGI to match your local network settings, and the specific IP address you picked for it and put into the settings.yml file:
```
> setenv netaddr 192.168.0.34
```
The address above is only a sample. You should pick an unused IP in your local network's subnet.


## Net boot into FX to Partition Disks 

Now examine the final output of the vagrant provision or vagrant up command, to find the proper command to boot into fx, the SGI disk partitioner.

* Look for:  __ Partitioners found
* copy and paste that entire line starting with bootp into the PROM (doing this via serial is easier to cut and paste.)
* Older systems use fx.ARCS (such as Indigos and Indy and some O2s)
* O2 and newer systems use fx.64
```
> bootp():/6.5.30/Overlay/disc1/stand/fx.64
Setting $netaddr to 192.168.251.34 (from server )
Obtaining /6.5.30/Overlay/disc1/stand/fx.64 from server 
95040+26448+7168+2805248+50056d+5908+8928 entry: 0x8fd4aa40
Currently in safe read-only mode.
Do you require extended mode with all options available? (no) yes
SGI Version 6.5 ARCS BE  Jul 20, 2006
...
```
Newer systems will use fx.64
```
bootp():/6.5.30/Overlay/disc1/stand/fx.64
```

Now continue with the partitoning process.




### fx (Partitioner)

If you need to boot `fx` to label/partition your disk, open the command monitor and issue a command similar to this:

`bootp():/6.5.30/Overlay/disc1/stand/fx.ARCS`

where `/6.5.30/Overlay/disc1/stand/fx.ARCS` is a path relative to your selected IRIX version in the directory structure from above. When installing IRIX 6.5.x you'll want to use the partitioner included with the overlay set (first disc), but prior versions of IRIX usually locate the partitioner on the first install disc.

 Use `fx.ARCS` for R4xxx machines (like the O2) and `fx.64` for R5000+ machines (and others for older machines, I assume). Once `booterizer` finishes setup it lists any detected partitioners to help you find the correct path.

You should use fx to partition your internal disk- read the section "Partitioning the disk" at [Getting an Indy Desktop](https://blog.pizzabox.computer/posts/getting-an-indy-desktop/) for more thorough directions.

### inst (IRIX installer)
NOTE: After `booterizer` initializes, it displays a list of all `dist` subdirectories for your convenience. Use this list to preserve your sanity while running inst.

The installer can be reached through the monitor GUI as follows:

* At the maintenance boot screen, select "Install Software"
* If it prompts you for an IP address, enter the same address you entered into the Vagrantfile config for `clientip`.
* Use `booterizer` as the install server hostname.
* For the installation path, this depends on your directory structure. If you use the structure example from above, you would use the path `6.5.30/Overlay/disc1/dist`. Notice the lack of leading `/`.
* This should load the miniroot over the network and boot into the installer.
* From inst, choose Option 13, Admin menu
  * booterizer generates a 'selections' file that contains all of the media paths for inst to load
  * ```load booterizer:selections```
  * You can press q to skip the readmes for each media item
  * Choose 'feature stream' when asked
  * When inst is done loading media, it will prompt for the next location. Type 
  * ```done```
* From inst, Admin menu
  * booterizer generates a 'commands' file that contains all of the commands for inst to run
  * ```source booterizer:commands```
  * NOTE: I've not yet confirmed these work. They appear to, but just in case, they are:
    ```
    return
    keep *
    install standard
    keep incompleteoverlays
    remove java_dev*
    remove java2_plugin*
    conflicts
    # there should be no conflicts
    go
    # go for a walk
    quit
    # go for another walk
    # the system will prompt to reboot
    ```


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


## Troubleshooting

## Problems running inst from Serial port

* see this page: https://support.hpe.com/hpsc/doc/public/display?docId=emr_na-sg2636en_us&docLocale=en_US
* ensure in the PROM that your console variable is set to d.
* if it is set to g you will have errors and kernel panics
```
setenv console d
```
And then continue installation as above.


## Ansible fails to pull images
* During extraction if you get this ansible failure:
```
TASK [fetch_files : Extracting overlay disc 1] *********************************
fatal: [default]: FAILED! => changed=false 
  msg: Failed to find handler for "/vagrant/irix/6.5.30/Overlay/disc1/disc1.tar.gz". Make sure the required command to extract the file is installed. Command "/bin/tar" could not handle archive. Command "unzip" not found.
```

the file didn't download fully. vagrant ssh into the host, move into that directory and delete the tar file. Then use the vagrant provision command to pull that tarball again and re-extract.

* Example
```
$ rm /vagrant/irix/6.5.30/Overlay/disc1/disc1.tar.gz
```
* then back on you main host run the provision again:
```
~/booterizer (master) $ vagrant provision
```



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
