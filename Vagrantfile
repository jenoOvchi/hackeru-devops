VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.define "master" do |master|
    master.vm.box = "centos/7"
    master.vm.network "forwarded_port", guest: 8080, host: 8080
    master.vm.network "private_network", ip: "192.168.10.2"
    master.vm.provider "virtualbox" do |v|
       v.memory = 1024
       v.cpus = 1
     end
    master.vm.provision "shell", inline: <<-SHELL
      sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/g' /etc/ssh/sshd_config    
      sudo systemctl restart sshd
    SHELL
  end

  config.vm.define "slave" do |slave|
    slave.vm.box = "centos/7"
    slave.vm.network "private_network", ip: "192.168.10.3"
    slave.vm.provider "virtualbox" do |v|
       v.memory = 1024
       v.cpus = 1
     end
    slave.vm.provision "shell", inline: <<-SHELL
      sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/g' /etc/ssh/sshd_config    
      sudo systemctl restart sshd
    SHELL
  end
end
