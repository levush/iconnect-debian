Vagrant.configure(2) do |config|
  config.vm.box = "debian/stretch64"

  config.vm.provider "virtualbox" do |vb|
    vb.name = "iconnect-debian"
    vb.customize ["modifyvm", :id, "--usb", "on"]
  end

  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.synced_folder ".", "/home/vagrant/iconnect-debian", owner: "vagrant", group: "vagrant"

  config.vm.provision "shell", inline: <<-SHELL
    sudo apt-get update
    sudo apt-get install -y git u-boot-tools wget patch util-linux dosfstools lzma debootstrap qemu-user-static bin-fmtsupport bc libssl-dev
  SHELL
end
