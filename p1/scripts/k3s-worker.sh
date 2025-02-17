#!/bin/bash

NODE_IP="192.168.56.111"

# Get the token from the shared folder
TOKEN=$(cat /vagrant/token)

# Install K3s agent (worker) and join the master node
curl -sfL https://get.k3s.io | K3S_URL=https://192.168.56.110:6443 K3S_TOKEN=$TOKEN  sh -s - --node-ip=$NODE_IP