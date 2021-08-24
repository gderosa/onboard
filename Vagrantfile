# -*- mode: ruby -*-
# vi: set ft=ruby :

DEBIAN_BOX = "debian/bullseye64"
WORKING_DIR = "/vagrant"
APP_USER = "vagrant"
PROVISIONER_ARGS = [WORKING_DIR, APP_USER]

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  config.vm.define "mgy", primary: true do |mgy|
    # The most common configuration options are documented and commented below.
    # For a complete reference, please see the online documentation at
    # https://docs.vagrantup.com.

    # Every Vagrant development environment requires a box. You can search for
    # boxes at https://vagrantcloud.com/search.
    mgy.vm.box = DEBIAN_BOX

    mgy.vm.hostname = "mgy"

    # Disable automatic box update checking. If you disable this, then
    # boxes will only be checked for updates when the user runs
    # `vagrant box outdated`. This is not recommended.
    # config.vm.box_check_update = false

    # Create a forwarded port mapping which allows access to a specific port
    # within the machine from a port on the host machine. In the example below,
    # accessing "localhost:8080" will access port 80 on the guest machine.
    # NOTE: This will enable public access to the opened port
    mgy.vm.network "forwarded_port", guest: 4567, host: 4567
    mgy.vm.network "forwarded_port", guest: 443,  host: 4443

    # Create a forwarded port mapping which allows access to a specific port
    # within the machine from a port on the host machine and only allow access
    # via 127.0.0.1 to disable public access
    # config.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"

    # Create a private network, which allows host-only access to the machine
    # using a specific IP.
    mgy.vm.network "private_network",  # may also be used as vlan 1 access
      auto_config: false, # or will reset what margay-persist has configured on the interface
      virtualbox__intnet: "default_access"

    mgy.vm.network "private_network",
      auto_config: false, # or will reset what margay-persist has configured on the interface
      virtualbox__intnet: "vlan_trunk"

    mgy.vm.network "private_network",
      auto_config: false, # or will reset what margay-persist has configured on the interface
      virtualbox__intnet: "vlan2_access"

    mgy.vm.synced_folder ".", "/vagrant"

    mgy.vm.provision "core",
        type: "shell",
        path: "./etc/scripts/platform/debian/setup.sh",
        args: PROVISIONER_ARGS

    # Make sure the VBox shared folder is mounted before the Margay systemd service is invoked
    VAGRANT_MOUNT_TEMPLATE = <<-EOF
[Unit]
Description=Vagrant Shared Folder

[Mount]
What=vagrant
Where=/vagrant
Type=vboxsf
Options=uid=`id -u vagrant`,gid=`id -g vagrant`

[Install]
RequiredBy=margay.service margay-persist.service
EOF

    mgy.vm.provision "shell", inline: <<-EOF
      cat > /etc/systemd/system/vagrant.mount <<EOFF
#{VAGRANT_MOUNT_TEMPLATE}
EOFF
      systemctl daemon-reload
      systemctl enable vagrant.mount
    EOF

    # Modules

    mgy.vm.provision "openvpn",
        type: "shell",
        path: "./modules/openvpn/etc/scripts/platform/debian/setup.sh",
        args: PROVISIONER_ARGS

    # Optional modules

    # Actually deploy all other AAA/Hotspot -related modules as well: chilli etc.
    # Not automatically run on provision, you have to explicitly call it with
    #    vagrant provision margay --provision-with radius
    # after the first provision has been completed.
    mgy.vm.provision "radius",
        type: "shell",
        path: "./modules/radius-admin/etc/scripts/platform/debian/setup.sh",
        args: PROVISIONER_ARGS,
        run: "never"

    # Similarly, for qemu/virt (also enable the jQQueryFileTree module)
    mgy.vm.provision "virt",
        type: "shell",
        path: "./modules/qemu/etc/scripts/platform/debian/setup.sh",
        args: PROVISIONER_ARGS,
        run: "never"

    # Is there a way to emulate a Wi-Fi network?
    mgy.vm.provision "ap",
        type: "shell",
        path: "./modules/ap/etc/scripts/platform/debian/setup.sh",
        args: PROVISIONER_ARGS,
        run: "never"

  end

  config.vm.define "mgy_downstr", primary: true do |mgy_downstr|  # downstream switch, currently a mgy, could be an Arista, Cisco, etc.
    mgy_downstr.vm.box = DEBIAN_BOX
    mgy_downstr.vm.hostname = "mgy_downstr"

    mgy_downstr.vm.network "forwarded_port", guest: 4567, host: 4568
    mgy_downstr.vm.network "forwarded_port", guest: 443,  host: 4444

    mgy_downstr.vm.network "private_network",
      auto_config: false, # or will reset what margay-persist has configured on the interface
      virtualbox__intnet: "vlan_trunk"

    mgy_downstr.vm.network "private_network",
      auto_config: false, # or will reset what margay-persist has configured on the interface
      virtualbox__intnet: "downstr_vlan_1_access"

    mgy_downstr.vm.network "private_network",
      auto_config: false, # or will reset what margay-persist has configured on the interface
      virtualbox__intnet: "downstr_vlan_2_access"

    # Enable provisioning with a shell script. Additional provisioners such as
    # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
    # documentation for more information about their specific syntax and use.
    mgy_downstr.vm.provision "core",
        type: "shell",
        path: "./etc/scripts/platform/debian/setup.sh",
        args: PROVISIONER_ARGS
  end

  # The client machine may be any OS, but for economy of storage and download time,
  # it's based on the same base box.
  config.vm.define "client", autostart: false do |mgyc|
    mgyc.vm.box = DEBIAN_BOX
    mgyc.vm.hostname = "mgyclient"
    mgyc.vm.network "private_network",
      auto_config: false,
          # Vagrant auto_config would otherwise mess things up here,
          # modifying /etc/network/interfaces so to remove the default gw from
          # margay (ordinary DHCP or chillispot).
      virtualbox__intnet: "default_access"
    mgyc.vm.provider "virtualbox" do |vb|
      vb.gui = true
      # https://stackoverflow.com/a/24253435
      vb.customize ["modifyvm", :id, "--vram", "16"]
    end
    mgyc.vm.provision "shell", inline: <<-EOF
      # restore default VBox NAT interface networking (if it has been disabled previously to use margay-connected interface eth1)
      ip link set up dev eth0
      # ASSUME dhclient is the dhcp client
      if (ps aux | grep dhclient | grep eth0 | grep -v grep); then
        if (ip route | grep default | grep -v grep); then
          ip route replace default via 10.0.2.2 dev eth0
        else
          ip route add default via 10.0.2.2 dev eth0
        fi
      else
        dhclient eth0
      fi

      export DEBIAN_FRONTEND=noninteractive
      apt-get update
      apt-get -y upgrade
      apt-get install -y lightdm openbox lxterminal psmisc firefox-esr
      systemctl start lightdm

      # Remove default Internet connection, it will use the second interface behind
      # margay (now that provisioning is done and software downloaded).

      cat > /etc/network/interfaces <<EOFF
# Auto-generated by a custom Vagrant provisioner for margay client.

# source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

# Default VBox NAT
auto eth0
iface eth0 inet dhcp
pre-up sleep 2
post-up ip route del default dev \\$IFACE || true

# Interface connected to Margay
auto eth1
iface eth1 inet dhcp
EOFF

    systemctl restart networking

    EOF
  end
end
