# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "jammy-server-cloudimg-amd64-vagrant.box"
  config.vm.box_url = "file://./jammy-server-cloudimg-amd64-vagrant.box"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = 2048
    vb.cpus = 2
  end

  config.ssh.verify_host_key = false

  # ------------------------------------------------------------
  # Воркер-ноды (создаются первыми)
  # ------------------------------------------------------------
  (1..2).each do |i|
    config.vm.define "k3s-worker-#{i}" do |worker|
      worker.vm.hostname = "k3s-worker-#{i}"
      worker.vm.network "private_network", ip: "192.168.56.1#{i}"
    end
  end

  # ------------------------------------------------------------
  # Мастер-нода (создаётся после воркеров)
  # ------------------------------------------------------------
  config.vm.define "k3s-master" do |master|
    master.vm.hostname = "k3s-master"
    master.vm.network "private_network", ip: "192.168.56.10"

    # Синхронизация папки с Ansible плейбуками
    master.vm.synced_folder "./ansible", "/home/vagrant/ansible"

    # Установка Ansible и копирование SSH ключей
    master.vm.provision "shell",
      inline: <<-SHELL
        sudo apt-get update
        sudo apt-get install -y ansible sshpass
        
        # Копируем ключи Vagrant для доступа к воркерам
        mkdir -p /home/vagrant/.ssh
        cp /vagrant/.vagrant/machines/k3s-worker-1/virtualbox/private_key /home/vagrant/.ssh/worker1_key
        cp /vagrant/.vagrant/machines/k3s-worker-2/virtualbox/private_key /home/vagrant/.ssh/worker2_key
        chmod 600 /home/vagrant/.ssh/worker*
        chown -R vagrant:vagrant /home/vagrant/.ssh
      SHELL
  end
end