# Overview for expect scripts
If you're daring, you can try these expect scripts to speed up your install.

You'll need a Linux box, a serial console cable, and likely a serial to USB adapter.


# Installation

* Run 'vagrant up'
* If asked, pick the ethernet connection for bridged interface

* Note the partitioner entry for fx.ARCS
```
bootp():/30-Overlays1/stand/fx.ARCS
```

* Connect serial cable.
* Run screen on linux
```
screen /dev/ttyUSB0 9600
```

# prom
* Put the SGI into PROM 
```
printenv
```
Note the MAC address: 

```
eaddr=08:00:69:0e:af:65"
```

* Note the current settings:
```

ConsoleOut=video()
ConsoleIn=keyboard()
console=g
```

* Modify settings
```
setenv ConsoleOut serial(0)
setenv ConsoleIn serial(0)
setenv console d
```

* Run the expect scripts 
    * format_drives.expect partitions the volume.
    * install_system.expect formats the partitions, then installs IRIX from bootp.

NOTICE: This erases your drive. 

# Post install
When the install is complete, the system will ask to be rebooted.

After the reboot, log in from console as root / no password. 

reboot

Hit 'escape' several times, just after the chime, to bring up PROM.

# Reset settings
```
setenv ConsoleOut video()
setenv ConsoleIn keyboard()
setenv console g
```

The system will reboot again, to the GUI. 

Run EZSetup.