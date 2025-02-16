Vagrant.configure(2) do |config|
# [...]
    config.vm.box = "ubuntu/bionic64"
    config.vm.define "apommierS" do |control|
        control.vm.hostname = "apommierS"
        control.vm.network "private_network", ip: "192.168.56.110"
        control.vm.provider "virtualbox" do |v|
            v.name = "apommierS"
            v.memory = "512"
            v.cpus = 1
        end
    # [...]
    end

    # config.vm.provision "shell", inline: ""
    # control.vm.provision "shell", path: REDACTED
    # end

    config.vm.define "apommierSW" do |control|
        control.vm.hostname = "apommierSW"
        control.vm.network "private_network", ip: "192.168.56.111"
        control.vm.provider "virtualbox" do |v|
            v.name = "apommierSW"
            v.memory = "512"
            v.cpus = 1
        end
    # [...]
    end

    # config.vm.provision "shell", inline: <<-SHELL
    # [..]
    # SHELL
    # control.vm.provision "shell", path: REDACTED
    # end
end