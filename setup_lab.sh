#!/bin/bash

# Install Necessary Packages in order to navigate this Project (People for M1 Mac / using QEMU

# Install Homebrew if not installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install necessary packages
brew install libvirt qemu pkg-config

# Set environment variable
echo 'export PKG_CONFIG_PATH="/usr/local/opt/libvirt/lib/pkgconfig"' >> ~/.zshrc
source ~/.zshrc  # or ~/.bash_profile

# Install Xcode command line tools
xcode-select --install

# Try to install the Vagrant plugin again
vagrant plugin install vagrant-libvirt
