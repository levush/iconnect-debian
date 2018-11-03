Vagrant.configure(2) do |config|
  config.vm.box = "debian/stretch64"

  config.vm.provider "virtualbox" do |vb|
    vb.name = "iconnect-debian"
    vb.customize ["modifyvm", :id, "--usb", "on"]
    vb.memory = 8192
    vb.cpus = 4
  end

  config.vm.provider "libvirt" do |lv|
    lv.memory = 8192
    lv.cpus = 4
  end

  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.synced_folder ".", "/home/vagrant/iconnect-debian", owner: "vagrant", group: "vagrant"

  config.vm.provision "shell", inline: <<-SHELL
    sudo apt-get update
    cd /home/vagrant/iconnect-debian
    sudo ./run.sh setup_packages
  SHELL
end
