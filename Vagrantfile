# booterizer
# vagrant configuration
# LICENSE: MIT
require 'yaml'

#################################################################
# Change settings in 'settings.yml' to match your environment
#################################################################
settings =      YAML.load_file 'settings.yml'

# irixversion install 6.5.30, 6.5.22 or 5.3
irixversion =   settings['booterizer']['irixversion']
# installmethod can be via CD images or remote fetch from Internet
installmethod = settings['booterizer']['installmethod']
installmirror = settings['booterizer']['installmirror']

# your SGI box's hostname
clientname =    settings['booterizer']['clientname']
# whatever domain that you make up
clientdomain =  settings['booterizer']['clientdomain']
# timezone
tzone =    settings['booterizer']['tzone']

# Internal network your SGI, Virtual Machine will be on
network =       settings['booterizer']['network']
# Internal network's netmask
netmask =       settings['booterizer']['netmask']
# your virtual machine (bootp/tftp server]) will get this IP
hostip =        settings['booterizer']['hostip']
# your SGI box's IP address that you make up and set in prom via setenv netaddr
clientip =      settings['booterizer']['clientip']
# your SGI box's physical hardware address, from printenv at PROM - or eaddr for older PROM
clientether =   settings['booterizer']['clientether']
default_gw =    settings['booterizer']['default_gw']
nameserver =    settings['booterizer']['nameserver']


# Handle single-NIC setups
singlenic = settings['booterizer']['singlenic']

if singlenic != "true"
  # With dual NICs, you must specify which NIC will be directly connected to your SGI box.
  #   In my case, it's the ethernet adapter, which is en0 
  bridgenic = settings['booterizer']['bridgenic']
end


# Your user account for your SGI box
myuser =        settings['booterizer']['myuser']
# Your desired shell 
  # if this doesn't exist, it defaults to /bin/csh
myshell =       settings['booterizer']['myshell']

# FTP urls

if irixversion == "6.5.30"
  ftpurls = YAML.load_file 'irix.6.5.30.yml'
elsif irixversion == "6.5.22"
  ftpurls = YAML.load_file 'irix.6.5.22.yml'
elsif irixversion == "5.3"
  ftpurls = YAML.load_file 'irix.5.3.yml'
end

foundation_baseurl    = ftpurls['ftpurls']['foundation']['baseurl']
foundation_disc1      = ftpurls['ftpurls']['foundation']['disc1']
foundation_disc2      = ftpurls['ftpurls']['foundation']['disc2']
foundation_nfs        = ftpurls['ftpurls']['foundation']['nfs']
overlay_baseurl       = ftpurls['ftpurls']['overlay']['baseurl']
overlay_apps          = ftpurls['ftpurls']['overlay']['apps']
overlay_capps         = ftpurls['ftpurls']['overlay']['capps']
overlay_disc1         = ftpurls['ftpurls']['overlay']['disc1']
overlay_disc2         = ftpurls['ftpurls']['overlay']['disc2']
overlay_disc3         = ftpurls['ftpurls']['overlay']['disc3']
devel_baseurl         = ftpurls['ftpurls']['devel']['baseurl']
devel_devlibs         = ftpurls['ftpurls']['devel']['devlibs']
devel_devfoundations  = ftpurls['ftpurls']['devel']['devfoundations']
devel_mipspro         = ftpurls['ftpurls']['devel']['mipspro']
devel_update          = ftpurls['ftpurls']['devel']['update']
devel_c               = ftpurls['ftpurls']['devel']['c']
devel_cee             = ftpurls['ftpurls']['devel']['cee']
devel_cpp             = ftpurls['ftpurls']['devel']['cpp']
devel_ap              = ftpurls['ftpurls']['devel']['ap']
devel_prodev          = ftpurls['ftpurls']['devel']['prodev']
extras_baseurl        = ftpurls['ftpurls']['extras']['baseurl']
extras_perfcopilot    = ftpurls['ftpurls']['extras']['perfcopilot']
extras_sgifonts       = ftpurls['ftpurls']['extras']['sgifonts']
nekodeps              = ftpurls['ftpurls']['nekodeps']
bootstrap_baseurl     = ftpurls['ftpurls']['bootstrap']['baseurl']
bootstrap_openssh     = ftpurls['ftpurls']['bootstrap']['openssh']
bootstrap_python      = ftpurls['ftpurls']['bootstrap']['python']
bootstrap_wget        = ftpurls['ftpurls']['bootstrap']['wget']

#################################################################
# end of settings
#################################################################




current_dir = File.dirname(File.expand_path(__FILE__))     
disk_prefix = 'installdisk'
disk_ext ='.vdi'      
installdisk = "%s/%s%s" % [current_dir,disk_prefix,disk_ext] 

Vagrant.configure("2") do |config|
  config.vm.box = "debian/contrib-jessie64"
  config.vm.box_version = "8.11.0"
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
        installmirror: installmirror,
        clientname: clientname,
        clientdomain: clientdomain,
        clientip: clientip,
        clientether: clientether,
        netmask: netmask,
        network: network,
        nameserver: nameserver,
        default_gw: default_gw,
        hostip: hostip,
        myuser: myuser,
        myshell: myshell,
        tzone: tzone,
        current_dir: current_dir,
        foundation_baseurl: foundation_baseurl,
        foundation_disc1: foundation_disc1,
        foundation_disc2: foundation_disc2,
        foundation_nfs: foundation_nfs,
        overlay_baseurl: overlay_baseurl,
        overlay_apps: overlay_apps,
        overlay_capps: overlay_capps,
        overlay_disc1: overlay_disc1,
        overlay_disc2: overlay_disc2,
        overlay_disc3: overlay_disc3,
        devel_baseurl: devel_baseurl,
        devel_devlibs: devel_devlibs,
        devel_devfoundations: devel_devfoundations,
        devel_mipspro: devel_mipspro,
        devel_update: devel_update,
        devel_c: devel_c,
        devel_cee: devel_cee,
        devel_cpp: devel_cpp,
        devel_ap: devel_ap,
        devel_prodev: devel_prodev,
        extras_baseurl: extras_baseurl,
        extras_perfcopilot: extras_perfcopilot,
        extras_sgifonts: extras_sgifonts,
        nekodeps: nekodeps,
        bootstrap_baseurl: bootstrap_baseurl,
        bootstrap_openssh: bootstrap_openssh,
        bootstrap_python: bootstrap_python,
        bootstrap_wget: bootstrap_wget
    }
    end
  else
    config.vm.provision "ansible" do |ansible|
      ansible.verbose = "v"
    ansible.playbook = "ansible/irix_ansible_setup.yml"
    ansible.extra_vars = {
        installmethod: installmethod,
        irixversion: irixversion,
        installmirror: installmirror,
        clientname: clientname,
        clientdomain: clientdomain,
        clientip: clientip,
        clientether: clientether,
        netmask: netmask,
        network: network,
        nameserver: nameserver,
        default_gw: default_gw,
        hostip: hostip,
        myuser: myuser,
        myshell: myshell,
        tzone: tzone,
        current_dir: current_dir,
        foundation_baseurl: foundation_baseurl,
        foundation_disc1: foundation_disc1,
        foundation_disc2: foundation_disc2,
        foundation_nfs: foundation_nfs,
        overlay_baseurl: overlay_baseurl,
        overlay_apps: overlay_apps,
        overlay_capps: overlay_capps,
        overlay_disc1: overlay_disc1,
        overlay_disc2: overlay_disc2,
        overlay_disc3: overlay_disc3,
        devel_baseurl: devel_baseurl,
        devel_devlibs: devel_devlibs,
        devel_devfoundations: devel_devfoundations,
        devel_mipspro: devel_mipspro,
        devel_update: devel_update,
        devel_c: devel_c,
        devel_cee: devel_cee,
        devel_cpp: devel_cpp,
        devel_ap: devel_ap,
        devel_prodev: devel_prodev,
        extras_baseurl: extras_baseurl,
        extras_perfcopilot: extras_perfcopilot,
        extras_sgifonts: extras_sgifonts,
        nekodeps: nekodeps,
        bootstrap_baseurl: bootstrap_baseurl,
        bootstrap_openssh: bootstrap_openssh,
        bootstrap_python: bootstrap_python,
        bootstrap_wget: bootstrap_wget
    }
    end
  end
end


Vagrant.configure("2") do |config|
  if singlenic == "true"
    config.vm.network "public_network", 
      ip: hostip, 
      bridge: bridgenic

    #config.vm.provision "shell",
    #  run: "always",
    #  inline: "route add default gw 192.168.0.1 ; echo "  
    config.vm.post_up_message = [ "booterizer running at ", hostip ]
  end
  config.vm.synced_folder ".", "/vagrant", type: "virtualbox"
end
