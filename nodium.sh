#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
NC='\033[0m'

read -p '{RED}Enter your masternode key (you created this in windows), then {GREEN}[ENTER]{NC}: ' GENKEY
echo -n "{BLUE}Installing pwgen...{NC}"
sudo apt-get install pwgen
echo -n "{BLUE}Installing dns utils...{NC}"
sudo apt-get install dnsutils
PASSWORD=$(pwgen -s 64 1)
WANIP=$(dig +short myip.opendns.com @resolver1.opendns.com)
echo -n "{BLUE}Installing with GENKEY: $GENKEY, RPC PASS: $PASSWORD, VPS IP: $WANIP...{NC}"
fallocate -l 3G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo -e "/swapfile none swap sw 0 0 \n" >> /etc/fstab

echo -n "{BLUE}Cloning GitHUB{NC}"
cd /root/
git clone https://github.com/nodiumproject/Nodium nodium

cd nodium
echo -n "{BLUE}Installing Pre-requisites{NC}"
sudo apt-get install -y pkg-config
sudo apt-get -y install build-essential autoconf automake libtool libboost-all-dev libgmp-dev libssl-dev libcurl4-openssl-dev git
sudo add-apt-repository ppa:bitcoin/bitcoin -y

sudo apt-get update
sudo apt-get upgrade
sudo apt-get install libdb4.8-dev libdb4.8++-dev

echo -n "{BLUE}Compiling the wallet (this can take 20 minutes){NC}"
sudo chmod +x share/genbuild.sh
sudo chmod +x autogen.sh
sudo chmod 755 src/leveldb/build_detect_platform
sudo ./autogen.sh
sudo ./configure
sudo make

echo "{BLUE}Starting daemon to create conf file{NC}"
cd src
./Nodiumd -daemon
sleep 30
./Nodium-cli getmininginfo
./Nodium-cli stop
echo "{BLUE}Stopping the daemon and writing config{NC}"

cat <<EOF > ~/.Nodium/Nodium.conf
rpcuser=nodiumadmin
rpcpassword=$PASSWORD
listen=1
server=1
daemon=1
logtimestamps=1
maxconnections=256
masternode=1
externalip=$WANIP
bind=$WANIP
masternodeaddr=$WANIP:27117
masternodeprivkey=$GENKEY
EOF

echo "{BLUE}setting up firewall to keep bad guys out...{NC}"
sudo apt-get install -y ufw
sudo apt-get update -y

#configure ufw firewall to keep bad guys out
sudo ufw default allow outgoing
sudo ufw default deny incoming
sudo ufw allow ssh/tcp
sudo ufw limit ssh/tcp
sudo ufw allow 6250/tcp
sudo ufw logging on

echo "{BLUE}Re-Starting the wallet...{NC}"
./Nodiumd -daemon