# booterizer

## TL;DR: Use a Raspberry Pi

The new Raspberry Pi version of Booterizer consists of pre-built images that you can write to a SD card.

This is a significantly easier and faster method than using Vagrant.

Follow the Raspberry Pi instructions below.

## Overview
booterizer is designed to quickly configure a Raspberry Pi or a disposable VM to boot a specific version of the SGI IRIX installer over the network on an SGI machine without a whole lot of fuss.

### Supported IRIX Versions

booterizer was designed for IRIX 6.5.30, the last version of IRIX for SGI. Use this as your first choice.
booterizer also fully supports IRIX 6.5.22 for older SGI systems that can run 6.5. Use this for Older Indys and Challenge L servers.
booterizer even works with IRIX 5.3 for classic SGI systems that cannot run 6.5.x (See Callahan's Booterizer 5.3 https://github.com/callahan-44/booterizer )

booterizer is not secure and may interfere with other network services (e.g. DHCP) so please don't leave it running long-term. I recommend only attaching the network interface to an isolated network for this purpose and then `vagrant halt` or `vagrant destroy` the VM when you are done installing.

The booterizer VM provides the following services:

* BOOTP server (via isc-dhcp)
* TFTP server (via tftpd-hpa)
* RSH server (via rsh-server)

NOTE: This fork no longer supports CD images. It may again in the future, if there is demand. If you must extract from CD media, see the original project at https://github.com/halfmanhalftaco/irixboot. This version will obtain the contents of the CD-ROMs for you automatically.

### Target SGI Systems

I am not sure what range of IRIX versions this will work with or what SGI machines are compatible. Personal testing and user reports show the following (at minimum) should be compatible:

| SGI System | CPU | IRIX System | Fx |  Verified by |
|------------|-----|-------------|----|--------------|
| Fuel       | all | 6.5.30 | fx.64 | unxmaal |
| Octane1    | all | 6.5.30 | fx.64 | diller |
| Octane2    | all   | 6.5.30 | fx.64 | unxmaal |
| Challenge L | R10k  | 6.5.22 | fx.ARCS | dillera |
| O2         | R4k   | 6.5.30 | fx.ARCS | dillera |
| O2         | R10k  | 6.5.30 | fx.64   | dillera |
| Origin 2100 | R12k | 6.5.30 | fx.64  | dillera |
| Indy       | R4600PC | 6.5.22 | fx.ARCS | PeteT |
| Indigo2    | R10k | 6.5.22 | fx.ARCS | dillera |

* Target Hardware
  * SGI O2
  * SGI Indigo
  * SGI Indigo2
  * SGI Octane

* Operating Systems
  * IRIX 6.5.22
  * IRIX 6.5.30

I suspect that most other hardware and OS versions released in those timeframes will also work (e.g. O2, server variants, etc.) SGI obviously kept the netboot/install process pretty consistent so I'd expect it to work on probably any MIPS-based SGI system.

### Where to get help

* Create a GitHub Issue vs this project
* Silicon Graphics User Group-  for support and dev community: https://sgi.sh/
* SGIDev chat on Discord: https://discord.gg/p2zZ7TZ

## NEW: Raspberry Pi Version
### Requirements

* Raspberry Pi 3 (This is what I have. Let me know if others work.)
* 32GB SD card
* Booterizer Pi Image from http://booterizer.com .
* Extraction software that supports bz2 (native on macOS. Use https://www.7-zip.org/ on Windows.)

### Pi Image Usage Instructions

* Extract the compressed image
* Write it to a 32GB+ SD card using Etcher or something
* Connect your SGI system via Ethernet to your Pi
* Boot your Pi
* Log in with default, pi/raspberry

```
sudo -i
cd /root/projects/github/booterizer
```

* Configure WiFi networking and connect to your network (use raspi-config)
* Modify settings.yml for ONLY these values:
  * irixversion = 6.5.30, 6.5.22, etc
  * clientname = your SGI's hostname
  * clientip = your SGI's IP. This MUST be 192.168.1.x for now. Change it later.
  * clientether = your SGI's MAC address

```
cd ansible/
ansible-playbook -i inventory.yml pooterizer.yml
reboot
```

* Skip down to the "Booting" section below
* You can find available partitioners and media by running /irix/display_results.sh

### Pi Image Build Instructions
Please see the README.md on the 'pi_support' branch.

## Vagrant Version

By default the Vagrant-based booterizer downloads IRIX 6.5.30 installation media from a mirror site. You can modify the media download URLs and point them to 6.5.22 by editing the settings.yml file at the root of this project and setting the
```
  irixversion:    "6.5.30"
```
to
```
  irixversion:    "6.5.22"
```
But leave the installmirror pointed to the same location!

### Requirements

* [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
* [Vagrant](https://www.vagrantup.com/downloads.html)
  * vagrant plugin install vagrant-guest_ansible
* Ansible/Python
* VM host with TWO network interfaces
  * I very much recommend using a host with two built-in interfaces, such as one WiFi and one Ethernet

#### Installation of Prerequisite software for macOS (Host)

* macOS has Brew - which can install Vagrant and VirtualBox for you from the command line with one command.
* Install Brew following directions at their website here: https://brew.sh/

* If you have brew installed you can install Vagrant, VB, and Ansible (Which will also install Python as a dependency):

```
$  brew cask install vagrant
$  brew cask install virtualbox
$  brew install ansible
```

* If you already have Python installed outside of Brew, instead of installing Ansible through Brew, install it through `pip`:

```
$  sudo pip install ansible
```

#### Installation of Prerequisite software for Ubuntu (Host)

* Installing recent vagrant must be done manually on older versions of Ubuntu, the procedure below will validate the package using its checksum. Just using apt-get will install an older version we don't want to use.
* We need to install VirtualBox (to run the virtual Linux server for the SGI installation media)
* We need to install Vagrant 2.2.3 to configure and kick of provisioning of the new VM
* We need to install Ansible to provision the new VM

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

### Verify Versions
Verify your installed versions:
```
vagrant -v
ansible --version
```
You should have:

* Ansible 2.7.6 or higher
* Vagrant 2.2.3 or higher

Having an exact version of VirtualBox is not critical- as long as you have the proper version of Vagrant, it will run VirtualBox for you.

### Vagrant Plugins

* Whichever host OS (macOS or Linux) you are using, install the Vagrant plugin with this command:

```
$ vagrant plugin install vagrant-vbguest
```
This will install a plugin that will automatically update any VirtualBox VMs with the latest guest additions

Now we can move on and start to configure the Vagrant file and start up the VM...

### Vagrant Booterizer Setup
By default, this vagrant VM will fetch proper IRIX installation packages as per the settings in `settings.yml`.

#### Settings
These settings are found in `settings.yml`. Edit them to suit your environment.

* Edit these lines

Set this to the version of IRIX you are installing.
```
irixversion: "6.5.30"
```

Currently installmethod is only ftp/http. Choose ftp here and http will be used if available. CD is no longer supported.
```
installmethod: "ftp"
```

Pick your install mirror

* the same files are in both locations
* choose only one of these

```
  installmirror: "https://sgi-irix.s3.amazonaws.com"
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

* this will be a unique, unused IP address in the subnet that your home/office router has created

```
hostip: '192.168.0.40'
```

The SGI client box's IP address

* this will be a unique, unused IP address in the subnet that your home/office router has created
* it cannot be the same as the Host IP above.

```
clientip: '192.168.0.41'
```

The SGI box's physical hardware address, from printenv at PROM
```
printenv eaddr
```
will return the SGI MAC address.

* older PROMs use the command: `eaddr` to obtain this
* if you cannot find the MAC address (some PROM do not show it - setup here and then watch the daemon.log file in the booterizer VM as you run the DHCP command to start the fx partitioner- you will see the real SGI MAC try and connect to your booterizer host. Copy it and re-configure)

```
clientether: '08:00:69:0e:af:65'
```

This is the name of the interface on your physical machine that's connected to your SGI box. In my case, it's the Ethernet adapter, which is en0.

* A Macintosh will usually use en0.
* By default the Linux kernel will usually assign this to eth0, however many distros have switched to [predictable naming](https://www.freedesktop.org/software/systemd/man/systemd.net-naming-scheme.html).
* If you are unsure of what your distro uses or do not know the interface name, check the interfaces using `ip link`.

```
bridgenic: 'en0'
```

#### Networking overview
The booterizer VM's fake network interfaces map to your physical host as follows:

| Physical Host | booterizer |
| --- | --- |
| Home LAN-connected NIC | Adapter 1, NAT, eth0 |
| SGI-connected NIC | Adapter 2, Bridged, eth1 |

NOTE: This VM starts a BOOTP server that will listen to broadcast traffic on your network. It is configured to ignore anything but the target system but if you have another DHCP/BOOTP server on the LAN segment the queries from the SGI hardware may get answered by your network's existing DHCP server which will cause problems. You may want to temporarily disable DHCP/BOOTP if you are running it on your LAN, configure it to not reply to queries from the SGI system, or put SGI hardware on a separate LAN (my recommendation).

* Note: This is usually not an issue, but it _may_ be, YMMV

##### One possible setup
![Image of a possible network setup for Booterizer](docs/booterizer_network_v1a.png?raw=true "Booterizer Network Setup")

#### IRIX media
This VM will now be able to sync installation media from S3 using HTTP.

Vagrant will automatically create a vagrant/irix directory on your host machine that is shared between it and the VM. It will then fetch the installation media archives only if they are missing from that directory.

You can keep both 6.5.22 and 6.5.30 media on the same host for different installations on various SGI machines.

Now that your configuration is complete, you're ready to start up the VM and set up the SGI.
```
$ vagrant up
```

## Booting your SGI from Booterizer (Raspberry Pi or Vagrant)

### Set IP address in PROM

When the PROM menu appears choose: Enter Command Monitor

* Set the netaddr of your SGI to match your local network settings, and the specific IP address you picked for it and put into the settings.yml file:

```
> setenv netaddr 192.168.0.34
```
The address above is only a sample. You should pick an unused IP in your local network's subnet.

### Setting Console Output in PROM

To help installations it's often easier to do an install via the SGI's serial port and your host computer (Mac or Ubuntu). With serial port you are able to:

* copy and paste commands from this page onto the serial comms program running on your workstation
* save the output from the SGI for posterity or help

Assuming you have connected up your SGI's serial port 1 to your workstation, and you are running a serial app, and you have set it to 9006/8/N/E then you are probably seeing the PROM menu and other characters from the SGI serial port during the system POST.

To setup the console to serial output for the installation you must set this console variable:

#### Set for Serial Output
```
setenv console d
```

This will ensure a smooth installation session.

When you are done you should set the console back to graphical virtual console:

#### Set for Graphics Output
```
setenv console g
```

#### Setting System Timezone
While you are in the PROM you should set the timezone to something appropriate for where you live.
```
setenv Timezone EST5EDT
```
would set the timezone to Eastern Time for example.

### FX to Partition Disks

Now examine the final output of the `vagrant provision` or `vagrant up` command, to find the proper command to boot into fx, the SGI disk partitioner.

* Look for:  __ Partitioners found

```
   __________________  Partitioners found __________________
    bootp():/6.5.30/Overlay/disc1/stand/fx.64
    bootp():/6.5.30/Overlay/disc1/stand/fx.ARCS

```

* copy and paste that entire line starting with bootp into the PROM (doing this via serial is easier to cut and paste.)
* Older systems use fx.ARCS (such as Indigos, Indys, and some O2s with R4k CPUs)
* O2 and newer systems use fx.64

#### Starting the fx Partitioner
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
Now continue with the partitioning process.

#### Using the fx Partitioner

You should use fx to partition your internal disk- read the section "Partitioning the disk" at [Getting an Indy Desktop](https://blog.pizzabox.computer/posts/getting-an-indy-desktop/) for more thorough directions.

In a nutshell, you want to [re]partition and then select [ro]ot only. Then `..` to escape that menu and [ex]it to quit fx and go back to the PROM to start a remote installation to install IRIX on the newly partitioned hard drive.

Here is a run-thru:
```
----- please choose one (? for help, .. to quit this menu)-----
[exi]t             [d]ebug/           [l]abel/           [a]uto
[b]adblock/        [exe]rcise/        [r]epartition/
fx> r

----- partitions-----
part  type        blocks            Megabytes   (base+size)
  0: xfs      266240 + 585671260     130 + 285972
  1: raw        4096 + 262144         2 + 128
  8: volhdr        0 + 4096           0 + 2
 10: volume        0 + 585937500       0 + 286102

capacity is 585937500 blocks

----- please choose one (? for help, .. to quit this menu)-----
[ro]otdrive           [o]ptiondrive         [e]xpert
[u]srrootdrive        [re]size
fx/repartition> ro

fx/repartition/rootdrive: type of data partition = (xfs)
Warning: you will need to re-install all software and restore user data
from backups after changing the partition layout.  Changing partitions
will cause all data on the drive to be lost.  Be sure you have the drive
backed up if it contains any user data.  Continue? yes


----- please choose one (? for help, .. to quit this menu)-----
[ro]otdrive           [o]ptiondrive         [e]xpert
[u]srrootdrive        [re]size
fx/repartition> ..

----- please choose one (? for help, .. to quit this menu)-----
[exi]t             [d]ebug/           [l]abel/           [a]uto
[b]adblock/        [exe]rcise/        [r]epartition/
fx> exi
```

#### Running inst (IRIX installer)

NOTE: After `booterizer` initializes, it displays a list of all `dist` subdirectories for your convenience. Use this list to preserve your sanity while running inst.

The installer can be reached through the monitor GUI as follows:

* At the maintenance boot screen, select "Install Software"
* If it prompts you for an IP address, enter the same address you entered into the Vagrantfile config for `clientip`.
* Use `booterizer` as the install server hostname.
* For the installation path, this depends on your directory structure. If you use the structure example from above, you would use the path `/6.5.30/Overlay/disc1/dist`.
  * NOTE: I really don't understand why, but some PROMs and architectures insist you remove the leading '/' from the path. If you get errors or inst otherwise fails, try `6.5.30/Overlay/disc1/dist`.
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
    [elf binaries are prepared for use]
    # the system will prompt to reboot
    ```

#### Example run
```
System Maintenance Menu

1) Start System
2) Install System Software
3) Run Diagnostics
4) Recover System
5) Enter Command Monitor

Option? 2


                         Installing System Software...

                       Press <Esc> to return to the menu.



1) Remote Directory  2)[Local CD-ROM]
      *a) Local SCSI CD-ROM drive 6, on controller 0

Enter 1-2 to select source type, a to select the source, <esc> to quit,
or <enter> to start: 1


Enter the name of the remote host: 192.168.251.99
Enter the remote directory: 6.5.30/Overlay/disc1/dist


1)[Remote Directory]  2) Local CD-ROM
      *a) Remote directory 6.5.30/Overlay/disc1/dist from server 192.168.251.99.

Enter 1-2 to select source type, a to select the source, <esc> to quit,
or <enter> to start:


Setting $netaddr to 192.168.251.82 (from server )
Copying installation program to disk.
......... 10% ......... 20% ......... 30% ......... 40% ......... 50%
......... 60% ......... 70% ......... 80% ......... 90% ......... 100%
Copy complete
IRIX Release 6.5 IP27 Version 07202013 System V - 64 Bit
Copyright 1987-2006 Silicon Graphics, Inc.
All Rights Reserved.
...
```
And from here inst runs and installs/creates a miniroot, then mounts the miniroot and then runs inst. Follow the directions above.

### IRIX installation is finished
At this point your system should come back up (ensure you go back into PROM and `setenv console g` if you set it to d for a serial installation!) and you can login as Root, no password.

Now there are many many more configurations you need to do before starting to use the system. Running EZSetup does a tiny fraction of these. The irix_ansible project (below docs) does a whole lot more!

#### Wiping a disk for clean IRIX install
Often you have have a drive with IRIX already installed, and you want to do a clean install. You need to wipe the disk with mkfs, running the partitioner on the drive is not enough. The reason is that if your partitions are exactly the same as they were on the old installation, when you run inst it will still pickup settings in /etc from the old install and assume you are doing an upgrade. To wipe the disk is easy- but you have to run inst, wipe, then reboot so that inst won't pick up the old installation and create a fresh miniroot and use default values.

Here is a sample run-thru:
```
Admin> 11

                   ** Clean Disks Procedure **

      If you agree to it, this procedure will clean your disks,
      removing all data from the root and (if present) the user
      file systems.

      Boot device partitions zero (0) and, if present, six (6)
      will be erased (using mkfs).  This will destroy all data on
      them.  These partitions will then be remounted under /root
      and (if present) /root/usr.

      If you have data on these file systems you want to save,
      answer "no" below, and backup the data before cleaning
      your disks.

      Any other file systems or logical volumes will be unmounted
      and forgotten about until you choose to reconfigure and
      remount them.


        Are you sure you want to clean your disks ?
                   { (y)es, (n)o, (sh)ell, (h)elp }: y

WARNING: There appears to be a valid file system on /dev/dsk/realroot already.
Making a new file system will destroy all existing data on it.

Make new file system on /dev/dsk/realroot? yes

Doing: mkfs -b size=4096 /dev/dsk/realroot
meta-data=/dev/dsk/realroot      isize=256    agcount=70, agsize=1048576 blks
         =                       sectsz=512   attr=0, parent=0
data     =                       bsize=4096   blocks=73208907, imaxpct=25
         =                       sunit=0      swidth=0 blks, unwritten=1
         =                       mmr=0
naming   =version 2              bsize=4096   mixed-case=Y
log      =internal log           bsize=4096   blocks=8936, version=1
         =                       sectsz=512    sunit=0 blks, lazy-count=0
realtime =none                   extsz=65536  blocks=0, rtextents=0

Mounting file systems:

    /dev/miniroot            on  /
    /dev/dsk/realroot        on  /root


Re-initializing installation history database
Reading product descriptions ..   0%
WARNING: Assuming no hist file
Reading product descriptions .. 100% Done.

```
And from here you just exit and reboot.

## Provisioning your IRIX host with irix_ansible
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
* Follow the irix_ansible README to create your own ansible vault
  * group_vars/default/vault.yml
* Place your vault password in /home/vagrant/.vault_pass.txt
* Continue with the irix_ansible README

### PRO TIP
Take a look in the expect/ directory for my own personal install scripts, written in expect. You can use them as a guide for what to select during an installation -- or if you're really brave/foolish, follow the enclosed README to run those scripts over serial console.

## Troubleshooting

### I'm having trouble with the Vagrant Booterizer
Generally, if you have trouble with the Vagrant-based booterizer, use the Pi version. It's easier, faster, and nearly everything's already done for you.

### Problems running inst from Serial port

* see this page: https://support.hpe.com/hpsc/doc/public/display?docId=emr_na-sg2636en_us&docLocale=en_US
* ensure in the PROM that your console variable is set to d.
* if it is set to g you will have errors and kernel panics

```
setenv console d
```
And then continue installation as above.

### Ansible fails to pull images

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
