#!/bin/bash

# Install homebrew
  echo "brew should be installed"
if ( which brew )
then
  echo "brew already installed"
else
  echo "installing brew"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install git
  echo "git should be installed"
if ( which git )
then 
  echo "git already installed"
else 
  echo "installing git"
  brew install git
fi

#install nano
  echo "nano should be installed"
if ( which nano )
then
  echo "nano already installed"
else
  echo "installing nano"
  brew install nano 
fi

# Install multipass
  echo "installing multipass on $(uname)"
if  ( which multipass )
then
  echo "multipass already installed on $(uname)"
else
  echo "installing multipass on $(uname)"  
  brew install --cask multipass
  sleep 5
fi

# Set Multipass local driver to Qemu
if [ "$(multipass get local.driver)" = "qemu" ]
then
  echo -e "\n==== Qemu local driver set ====\n"
else
  echo -e "\n==== Setting Qemu as Multipass local driver ====\n"
  multipass set local.driver=qemu
fi

# ssh keys
if [ stat "./id_ed25519" ]
then
  echo "trifecta ssh key exists"
else
  echo "creating ssh keys for trifecta"
  ssh-keygen -f ./id_ed25519 -t ed25519 -b 4096 -N ''
fi

# Create cloud-init.yaml
if [ -f cloud-init.yaml ] 
then
  echo -e "\n==== Cloud-init.yaml present ====\n"
else
  echo -e "\n==== Creating cloud-init.yaml ====\n"
  cat <<- EOF > cloud-init.yaml
users:
  - default
  - name: $USER
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - $(cat id_ed25519.pub)
EOF
fi

# Spinning up an ubuntu vm
if ( multipass info trifecta | grep Running )
then 
  echo "trifecta vm is running"
else 
  echo "launching a ubuntu vm named trifecta"
  multipass launch --name trifecta --cloud-init cloud-init.yaml
fi

# Copies webserver.sh to VM
scp -i ./id_ed25519 -o StrictHostKeyChecking=no webserver.sh aws-cli-install.sh jenkins-install.sh ansible-install.sh docker-install.sh amazon-cli-install.sh $USER@$(multipass info trifecta | grep IPv4 | awk '{ print $2 }'):~/

# SSH into trifecta VM
ssh -o StrictHostKeyChecking=no -i ./id_ed25519 "$(whoami | cut -d '\' -f2)@$(multipass info trifecta | grep IPv4 | awk '{ print $2 }')" 

# The commands below utilize multipass exec to manipulate the vm from another terminal. this is just here for notes and testing
# zsh create-vm.sh && multipass exec trifecta -- sudo apt update && multipass exec trifecta -- sudo apt install -y nginx &&  multipass exec trifecta -- curl localhost && multipass info trifecta

