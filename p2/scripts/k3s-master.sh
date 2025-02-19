#!/bin/bash

NODE_IP="192.168.56.110"

# Install K3s on the master node
curl -sfL https://get.k3s.io | sh -s - --node-ip=$NODE_IP

# Make sure kubectl is set up for the vagrant user
sudo mkdir -p /home/vagrant/.kube
sudo cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
sudo chown -R vagrant:vagrant /home/vagrant/.kube/config