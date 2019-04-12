# -*- mode: ruby -*-
# vi: set ft=ruby :

DEBIAN_BOX = "bento/debian-9"

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  config.vm.define "margay", primary: true do |mgy|
    # The most common configuration options are documented and commented below.
    # For a complete reference, please see the online documentation at
    # https://docs.vagrantup.com.

    # Every Vagrant development environment requires a box. You can search for
    # boxes at https://vagrantcloud.com/search.
    mgy.vm.box = DEBIAN_BOX

    mgy.vm.hostname = "margay"

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
    mgy.vm.network "private_network", ip: "10.192.168.11", netmask: "24",
      auto_config: false, # or will reset what margay-persist has configured on the interface
      virtualbox__intnet: "margay-net-downstream"

    # Create a public network, which generally matched to bridged network.
    # Bridged networks make the machine appear as another physical device on
    # your network.
    # config.vm.network "public_network"

    # Share an additional folder to the guest VM. The first argument is
    # the path on the host to the actual folder. The second argument is
    # the path on the guest to mount the folder. And the optional third
    # argument is a set of non-required options.

    # A symlink could work too? Current strategy is running as vagrant,
    # and generally being flexible/dynamic as per the user
    # Margay/OnBoard runs as. So the dir is still owned by vagrant
    # but compatibility with some legacy scripts is retained.

    mgy.vm.synced_folder ".", "/vagrant"

    # Enable provisioning with a shell script. Additional provisioners such as
    # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
    # documentation for more information about their specific syntax and use.
    mgy.vm.provision "shell", path: "./etc/scripts/platform/debian/setup.sh", args: ["/vagrant", "vagrant"]

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

    mgy.vm.provision "shell", path: "./modules/openvpn/etc/scripts/platform/debian/setup.sh", args: ["/vagrant", "vagrant"]

  end

  # The client machine may be any OS, but for economy of storage and download time,
  # it's based on the same base box.
  config.vm.define "client" do |mgyc|
    mgyc.vm.box = DEBIAN_BOX
    mgyc.vm.hostname = "mgyclient"
    mgyc.vm.network  "private_network", ip: "10.192.168.22", netmask: "24",
      virtualbox__intnet: "margay-net-downstream"
    mgyc.vm.provider "virtualbox" do |vb|
      vb.gui = true
      # vb.memory = "1024"
    end
    mgyc.vm.provision "shell", inline: <<-EOF
      export DEBIAN_FRONTEND=noninteractive
      apt-get update
      apt-get -y upgrade
      apt-get install -y lightdm openbox lxterminal qupzilla
      systemctl start lightdm
      # Remove default Internet connection, it will use the second interface behind
      # margay (now that provisioning is done and software downloaded).
      # ip route del default via 10.0.2.2 dev eth0
    EOF
  end
end
