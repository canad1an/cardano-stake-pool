#!/bin/bash
set -e
# Full credit for this script goes to: https://github.com/alessandrokonrad/Pi-Pool
# This script installs all necessary dependencies to build the the cardano-node and cardano-cli binaries

echo "Updating Ubuntu"
echo
sudo apt-get update
sudo apt-get upgrade
echo
echo "Installing dependencies"
echo
sudo apt-get install libsodium-dev build-essential pkg-config libffi-dev libgmp-dev libssl-dev libtinfo-dev libsystemd-dev zlib1g-dev make g++ tmux git jq wget libncursesw5 llvm -y
echo
echo "Installing Haskell platform"
echo
sudo apt-get install -y haskell-platform
wget https://github.com/canad1an/cardano-stake-pool/raw/master/files/cabal
chmod +x cabal
mkdir -p ~/.local/bin
mv cabal ~/.local/bin
sudo rm /usr/bin/cabal
echo 'export PATH="~/.local/bin:$PATH"' >> .bashrc
source ~/.bashrc
echo
echo "Done!"