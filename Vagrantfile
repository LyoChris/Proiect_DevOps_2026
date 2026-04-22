Vagrant.configure("2") do |config|

    os = "generic/rocky9"
    #host_net = "192.168.100"
    host_net = "192.168.56"
    config.vm.synced_folder '.', '/vagrant', disabled: true
    host_key = File.read(File.expand_path("~/.ssh/id_rsa.pub"))

    provision_steps = <<-SHELL
        echo "root:fiipractic" | chpasswd
        echo "PasswordAuthentication yes" > /etc/ssh/sshd_config.d/99-vagrant.conf
        echo "PermitRootLogin yes" >> /etc/ssh/sshd_config.d/99-vagrant.conf
        mkdir -p /root/.ssh
        chmod 700 /root/.ssh
        echo '#{host_key}' >> /root/.ssh/authorized_keys
        chmod 600 /root/.ssh/authorized_keys
        systemctl restart sshd
        dnf install -y git vim wget
    SHELL

    machines = { app: { hostname: "app.fiipractic.lan", title: "FiiPractic-App", memory: 2048, cpus: 2, ip: "#{host_net}.10" },
                gitlab: { hostname: "gitlab.fiipractic.lan", title: "FiiPractic-GitLab", memory: 4096, cpus: 4, ip: "#{host_net}.20", disk_size: "30GB" }
    }

    machines.each do |name, machine|
        config.vm.define name do |machine_config|
            machine_config.vm.box = os
            machine_config.vm.hostname = machine[:hostname]
            machine_config.vm.network "private_network", ip: machine[:ip]

            machine_config.vm.provider "libvirt" do |libvirt|
                libvirt.memory = machine[:memory]
                libvirt.cpus = machine[:cpus]
                libvirt.machine_type = "q35"
                libvirt.cpu_mode = "host-passthrough"
                libvirt.title = machine[:title]
            end

            if machine[:disk_size]
                machine_config.vm.disk :disk, size: machine[:disk_size], primary: true
            end

            machine_config.vm.provision "shell", inline: provision_steps
        end
    end

    # config.vm.define :app do |app_config|
    #     app_config.vm.provider "libvirt" do |libvirt|
    #         libvirt.memory = 2048
    #         libvirt.cpus = 2
    #         libvirt.machine_type = "q35"
    #         libvirt.cpu_mode = "host-passthrough"
    #         libvirt.title = "FiiPractic-App"
    #     end
    #
    #     app_config.vm.hostname = "app.fiipractic.lan"
    #     app_config.vm.box = os
    #     app_config.vm.network "private_network", ip: "#{host_net}.10"
    #
    #     app_config.vm.provision "shell", inline: <<-SHELL  # Optionally, we can add a provisioning step
    #     echo "root:fiipractic" | chpasswd
    #     echo "PasswordAuthentication yes" > /etc/ssh/sshd_config.d/99-vagrant.conf
    #     echo "PermitRootLogin yes" >> /etc/ssh/sshd_config.d/99-vagrant.conf
    #     echo '#{host_key}' >> /root/.ssh/authorized_keys
    #     systemctl restart sshd
    #     dnf install -y git
    #     dnf install -y wget
    #     dnf install -y vim
    #     SHELL
    # end
    #
    # config.vm.define :gitlab do |gitlab_config|
    #     gitlab_config.vm.provider "libvirt" do |libvirt|
    #         libvirt.memory = 4096
    #         libvirt.cpus = 4
    #         libvirt.machine_type = "q35"
    #         libvirt.cpu_mode = "host-passthrough"
    #         libvirt.title = "FiiPractic-GitLab"
    #     end
    #
    #     gitlab_config.vm.hostname = "gitlab.fiipractic.lan"
    #     gitlab_config.vm.disk :disk, size: "30GB", primary: true
    #     gitlab_config.vm.box = os
    #     gitlab_config.vm.network "private_network", ip: "#{host_net}.20"
    #
    #     gitlab_config.vm.provision "shell", inline: <<-SHELL  # Optionally, we can add a provisioning step
    #     echo "root:fiipractic" | chpasswd
    #     echo "PasswordAuthentication yes" > /etc/ssh/sshd_config.d/99-vagrant.conf
    #     echo "PermitRootLogin yes" >> /etc/ssh/sshd_config.d/99-vagrant.conf
    #     echo '#{host_key}' >> /root/.ssh/authorized_keys
    #     systemctl restart sshd
    #     dnf install -y git
    #     dnf install -y wget
    #     dnf install -y vim
    #     SHELL
    # end
end
