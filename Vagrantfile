# booterizer
# vagrant configuration
# LICENSE: MIT

#####
# Change these settings to match your environment
#####

irixversion = '6.5'

# installmethod can be via CD images or FTP
installmethod = "ftp"
installmirror = "us.irisware.net"

# your SGI box's hostname
clientname = 'sgi'
# whatever domain that you make up
clientdomain = 'dillera.org'

# Internal network your SGI will be on
network = '192.168.251.0' 
# Internal network's netmask
netmask = '255.255.255.0'
# your host pc will get this IP
hostip = '192.168.251.95'
# your sgi box's IP address that you make up
clientip = '192.168.251.35'
# your sgi box's physical hardwaxe address, from printenv at PROM
# my O2 clientether = '08:00:69:0e:af:65'

# O2
clientether = '08:00:69:0c:41:ea'
# my O300 clientether = '08:00:69:13:dd:42'

# This is the name of the interface on your physical machine that's connected to your SGI box
#   In my case, it's the ethernet adapter, which is en0 
bridgenic = 'en0'

# FTP urls

## IRIX foundation
foundation="http://us.irisware.net/sgi-irix/irix-6.5/network-installs/foundation1.tar.gz
http://us.irisware.net/sgi-irix/irix-6.5/network-installs/foundation2.tar.gz
http://us.irisware.net/sgi-irix/irix-6.5/network-installs/onc3nfs.tar.gz"

## 6.5.30 overlays
# overlay="http://us.irisware.net/sgi-irix/irix-6.5/network-installs/irix-6.5.22/apps.tar.gz
# http://us.irisware.net/sgi-irix/irix-6.5/network-installs/irix-6.5.22/disc1.tar.gz
# http://us.irisware.net/sgi-irix/irix-6.5/network-installs/irix-6.5.22/disc2.tar.gz
# http://us.irisware.net/sgi-irix/irix-6.5/network-installs/irix-6.5.22/disc3.tar.gz"

overlay="http://us.irisware.net/sgi-irix/irix-6.5/network-installs/irix-6.5.30/apps.tar.gz
http://us.irisware.net/sgi-irix/irix-6.5/network-installs/irix-6.5.30/disc1.tar.gz
http://us.irisware.net/sgi-irix/irix-6.5/network-installs/irix-6.5.30/disc2.tar.gz
http://us.irisware.net/sgi-irix/irix-6.5/network-installs/irix-6.5.30/disc3.tar.gz"


## Dev
devel="http://us.irisware.net/sgi-irix/development/developmentlibraries.tar.gz
http://us.irisware.net/sgi-irix/development/mipspro-74/devf_13.tar.gz
http://us.irisware.net/sgi-irix/development/mipspro-74/mipspro-7.4.3m.tar
http://us.irisware.net/sgi-irix/development/mipspro-74/mipspro744update.tar.gz
http://us.irisware.net/sgi-irix/development/mipspro-74/mipspro_c.tar.gz
http://us.irisware.net/sgi-irix/development/mipspro-74/mipspro_cee.tar.gz
http://us.irisware.net/sgi-irix/development/mipspro-74/mipspro_cpp.tar.gz
http://us.irisware.net/sgi-irix/development/mipspro-74/mipsproap.tar.gz
http://us.irisware.net/sgi-irix/development/mipspro-74/prodev.tar.gz"
## Extras
extras="http://us.irisware.net/sgi-irix/extras/perfcopilot.tar.gz
http://us.irisware.net/sgi-irix/extras/sgipostscriptfonts.tar.gz"

## Nekodeps
nekodeps="nekodeps_custom.0.0.1.tardist"

## Bootstrap
bootstrap="ftp://nonfree.irix.fun/pub/misc/openssh_bundle-0.0.1.tardist.gz
ftp://nonfree.irix.fun/pub/misc/python_bundle-0.0.1.tardist.gz
ftp://nonfree.irix.fun/pub/misc/wget_bundle-0.0.1.tardist.gz"


##### 
# end of settings
#####

current_dir = File.dirname(File.expand_path(__FILE__))     
disk_prefix = 'installdisk'
disk_ext ='.vdi'      
installdisk = "%s/%s%s" % [current_dir,disk_prefix,disk_ext] 

Vagrant.configure("2") do |config|
  config.vm.box = "debian/contrib-jessie64"
  config.vm.box_version = "8.11.0"
  #config.vm.network "public_network"
  config.vm.post_up_message = [ "booterizer configuration stage" ]
  
  config.vm.synced_folder ".", "/vagrant", type: "virtualbox"

  # Create XFS-formatted disk for extracted CD images
  config.vm.provider "virtualbox" do |v|
    unless File.exist?(installdisk)
      v.customize ['createhd', '--filename', installdisk, '--size', 50 * 1024]
    end
    v.customize ['storageattach', :id, '--storagectl', 'SATA Controller', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', installdisk]
  end
end

# Provision the new box with Ansible plays
Vagrant.configure("2") do |config|
  if Vagrant::Util::Platform.windows?
   config.vm.provision :shell do |shell|
      shell.inline = "sudo apt-get -y install wget curl"
    end 
    config.vm.provision :guest_ansible do |ansible|
      ansible.verbose = "v"
    ansible.playbook = "ansible/irix_ansible_setup.yml"
    ansible.extra_vars = {
        installmethod: installmethod,
        irixversion: irixversion,
        foundation: foundation,
        overlay: overlay,
        extras: extras,
        nekodeps: nekodeps,
        bootstrap: bootstrap,
        devel: devel,
        installmirror: installmirror,
        clientname: clientname,
        clientdomain: clientdomain,
        clientip: clientip,
        clientether: clientether,
        netmask: netmask,
        network: network,
        hostip: hostip,
        current_dir: current_dir
    }
    end
  else
    config.vm.provision "ansible" do |ansible|
      ansible.verbose = "v"
    ansible.playbook = "ansible/irix_ansible_setup.yml"
    ansible.extra_vars = {
        installmethod: installmethod,
        irixversion: irixversion,
        foundation: foundation,
        overlay: overlay,
        extras: extras,
        nekodeps: nekodeps,
        bootstrap: bootstrap,
        devel: devel,
        installmirror: installmirror,
        clientname: clientname,
        clientdomain: clientdomain,
        clientip: clientip,
        clientether: clientether,
        netmask: netmask,
        network: network,
        hostip: hostip,
        current_dir: current_dir
    }
    end
  end
end



Vagrant.configure("2") do |config|
  config.vm.box = "debian/contrib-jessie64"
  config.vm.box_version = "8.11.0"
  config.vm.network "public_network", ip: hostip, bridge: bridgenic
  config.vm.post_up_message = [ "booterizer running at ", hostip ]
  config.vm.synced_folder ".", "/vagrant", type: "virtualbox"
end
