:warning: This repo is **DEPRECATED**. 

# Run a Cardano Stake Pool on a Raspberry Pi 4

This guide will take you through every step required to create a cardano stake pool using just your Raspberri Pi. This is a fun and low cost solution to create a staking pool. Some steps at the beginning are manual, like flashing the ssd and microsd. Then some major sections like installing the prereqs and building the cardano node, will all be automated with shell scripts. This guide is intended for running a relay on a raspberry pi, and a separate raspberry pi for the producer. It is technically possibly to run them all together using docker, however for security and reliability, I have deployed them separately. 

## Our Solar Powered Cardano Staking Pool [SOLRP]
Hey guys as you're setting up your own pools please consider delegating your stake to our solar powered raspberry pi project: http://solarcardano.com/  
Ticker: [SOLRP]  
Telegram: https://t.me/SolarCardano  
Twitter: https://twitter.com/SOLRP_StakePool  
AdaPools: https://pooltool.io/pool/9728b10a926c048af938e5c52053319db5be921e8b698842c3afd3cc/  
And as always, reach out to me if you have any questions!  

## Required Hardware
* 2 8GB Raspberry Pi 4 (1 for the relay, 1 for the producer)
* 2 SSD 500GB (256GB should be fine, but 500GB gives plenty of room for expansion) [Specifically I bought this: SAMSUNG T7 Portable SSD 500GB]

## Configuration
* Your raspberry PIs will take up 2 IP addresses in your network. Go ahead and find some available IP space (Static is better) and write down the IPs, we'll need them in a later step.
* The doc is written for ubuntu 20, however i'm sure with some small tweaks you could run on ubuntu 18 (or as is). Additionally some more tweaks centos/rhel, etc.

## Getting Started: Flashing the images
To get started we need to flash the microsd with Raspberry Pi OS, and we need to flash the ssd with ubuntu 20. After we get the SSD setup as primary boot, we won't need the microsd. 

```
1. Download the Raspberry Pi Imager: https://www.raspberrypi.org/software/
2. Insert the microsd into your PC/Mac
3. Select the OS and the SD Card and Write the image (Tutorial: https://www.youtube.com/watch?v=J024soVgEeM)
	a. Microsd: Raspberry Pi OS
	b. SSD: Ubuntu 20.01.2 ARM64 (Direct download: https://ubuntu.com/download/raspberry-pi/thank-you?version=20.04.2&architecture=server-arm64+raspi)
4. Now we need to make the raspbian OS boot in headless mode so that you can ssh to the device, without having to setup a monitor, keyboard, mouse, etc.
	a. For headless setup, SSH can be enabled by placing a file named ssh, without any extension, onto the boot partition of the SD card from another computer. So literally just create a file called "ssh" in the boot partition of the microsd card, and you're done.
5. Make sure to connect an ethernet cable to your raspberry pi (if DHCP is configured, you should be able to get a local IP)
	a. If you would prefer to do a wireless setup, follow this doc. It will require adding a file to your rasbian (on the microsd, same as you did with the ssh) which you will do BEFORE you boot it on the raspberry pi: https://www.raspberrypi.org/documentation/configuration/wireless/headless.md
6. After the microsd is flashed, insert it into the raspberry Pi and power on the device. Make sure to connect your ssd to the raspberry Pi at this time
```

## Upgrading firmware and SSD Boot
After the raspberry Pi boots up, you should be able to ssh into the device. You'll need to look through your network config man to find the IP address that was assigned via DHCP.
Next step is to upgrade the firmware for our Raspberry Pi devices. Complete guide can be found here: https://www.raspberrypi.org/documentation/hardware/raspberrypi/booteeprom.md
After the firmware is upgraded and rebooted, next step is to prepare the Raspberry Pi to boot from SSD instead of microsd. Additionally we'll configure some ubuntu settings to make the boot seamless.  
**Default Raspberry Pi OS credentials: pi:raspberry (No need to change this since we're not using raspbian)**
  
**Run on both the raspberry Pi devices to upgrade firmware:**
```
sudo su
apt update && sudo apt full-upgrade -y
reboot
sudo su
fdisk -l  # (Make sure that you see your SSD in there, something like: Disk /dev/sda)

mkdir /mnt/ssdp1
mkdir /mnt/ssdp2
mount /dev/sda1 /mnt/ssdp1
mount /dev/sda2 /mnt/ssdp2
cd /mnt/ssdp1
zcat vmlinuz > vmlinux
nano config.txt

replace [pi4] section with
##################
[pi4]
max_framebuffers=2
dtoverlay=vc4-fkms-v3d
boot_delay
kernel=vmlinux
initramfs initrd.img followkernel
########################

wget https://raw.githubusercontent.com/canad1an/cardano-stake-pool/master/sh/auto_decompress_kernel.sh
chmod +x auto_decompress_kernel.sh
cd /mnt/ssdp2/etc/apt/apt.conf.d
wget https://raw.githubusercontent.com/canad1an/cardano-stake-pool/master/sh/999_decompress_rpi_kernel
chmod +x 999_decompress_rpi_kernel
cd /
umount /mnt/ssdp1
umount /mnt/ssdp2
rm /mnt/ssdp1 -rf
rm /mnt/ssdp2 -rf

rpi-eeprom-update -d -f /lib/firmware/raspberrypi/bootloader/stable/pieeprom-2020-07-31.bin
echo 'FIRMWARE_RELEASE_STATUS="stable"' > /etc/default/rpi-eeprom-update
reboot
sudo raspi-config # (This will load the GUI)
	Select Options:
		 6 Advanced Options
		 A6 Boot/Auto Login
		 B2 USB Boot
		 Finish
		 Reboot 
```

## Prepping Ubuntu
Congratulations! If you've made it this far, your raspberry Pi should be booted again, but this time via ssd and on Ubuntu. If you're using DHCP, you might need to search for the new ip address. We can make it static in the next few steps.  
First we're going to allocate space for swap. Then there is an optional section to make a static IP address, if you want to continue using DHCP, skip this step.  
Lastly we're going to configure a new user and setup some system settings.  
**Ubuntu default credentials: ubuntu:ubuntu** (Upon logging in, you will have to change this password)

**SWAP: Run on both raspberry Pi devices (Relay and Producer)**
```
sudo su
sudo fallocate -l 2G /swapfile # If you don't want 20G, then modify this number
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile swap swap defaults 0 0' >> /etc/fstab
reboot
free -m # You should at this point, see a line like this: [Swap:         2048           0       2048 ]
```

**ZRAM: Run on both raspberry Pi devices (Relay and Producer)**
```
sudo su
apt install zram-tools
echo -e "vm.vfs_cache_pressure=500" >> /etc/sysctl.conf
echo -e "vm.swappiness=100" >> /etc/sysctl.conf
echo -e "vm.dirty_background_ratio=1" >> /etc/sysctl.conf
echo -e "vm.dirty_ratio=50" >> /etc/sysctl.conf
reboot
```

**Static IP: Run on both raspberry Pi devices (Modify the IP address below for the relay and producer)**
```
sudo su
chmod 777 /etc/netplan/50-cloud-init.yaml
cat <<-EOF > /etc/netplan/50-cloud-init.yaml
# This file is generated from information provided by the datasource.  Changes
# to it will not persist across an instance reboot.  To disable cloud-init's
# network configuration capabilities, write a file
# /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg with the following:
# network: {config: disabled}
network:
    ethernets:
        eth0:
            addresses: 
                    - 192.168.1.51/24
            gateway4: 192.168.1.254
            nameservers:
                    addresses: [192.168.1.254]
    version: 2
EOF
chmod 644 /etc/netplan/50-cloud-init.yaml
netplan apply # ************As soon as you run this command, you will have to ssh into the NEW IP address************
sudo su
hostnamectl set-hostname pi-producer-node # Modify this for relay and producer
timedatectl set-timezone America/Chicago # Pick your current timezone
adduser cardanouser # This will ask you to set a password. You can skip all the other questions
adduser cardanouser sudo # Add user to sudo group
su cardanouser
```

## Building the node
We're almost there! Time to start building the node. There's some commands in here that take a long time to run (hours). Be patient, it will eventually build and you can move on to the next steps.

**Run on both raspberry Pi devices (Relay and Producer)**
```
mkdir "$HOME/tmp"
cd "$HOME/tmp"
wget https://raw.githubusercontent.com/canad1an/cardano-stake-pool/master/sh/start.sh
chmod +x start.sh
./start.sh
sudo mv "$HOME/.local/bin/cabal" /usr/local/bin
curl -sS -o prereqs.sh https://raw.githubusercontent.com/cardano-community/guild-operators/master/scripts/cnode-helper-scripts/prereqs.sh
chmod 755 prereqs.sh
./prereqs.sh
. "${HOME}/.bashrc"
cd ~/git
git clone https://github.com/input-output-hk/cardano-node --branch 1.25.1
cd cardano-node
echo -e "package cardano-crypto-praos\n  flags: -external-libsodium-vrf" > cabal.project.local
$CNODE_HOME/scripts/cabal-build-all.sh
sudo mv /home/cardanouser/.cabal/bin/* /usr/local/bin/
cd "$HOME/tmp"
wget https://github.com/canad1an/cardano-stake-pool/raw/master/files/cardano-cli
chmod +x cardano-cli
sudo mv /usr/local/bin/cardano-cli /usr/local/bin/cardano-cli.bak
sudo mv cardano-cli /usr/local/bin/
wget https://github.com/canad1an/cardano-stake-pool/raw/master/files/cardano-node
chmod +x cardano-node
sudo mv /usr/local/bin/cardano-node /usr/local/bin/cardano-node.bak
sudo mv cardano-node /usr/local/bin/
```

## Start the nodes and sync to mainnet
Last step is to start the nodes and let them sync up with the mainnet. This will take quite some time, possible even a day or so.

**Run on both raspberry Pi devices (Relay and Producer)**
```
cardano-cli --version
cardano-node --version
cd $CNODE_HOME/scripts
nano env      #(CNODE_PORT=6000  (if you want to modify the port replace 6000 with your desired port))
./deploy-as-systemd.sh #(A question will appear for topologyUpdater: Select No for producer node, select Yes for Relay)
sudo systemctl restart cnode
sudo systemctl status cnode
cd $CNODE_HOME/scripts/
./gLiveView.sh
```

## Security
This is probably the MOST important section in this list, so please don't skip it!
```
sudo su
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#Port 22/Port 6682/' /etc/ssh/sshd_config
echo 'AllowUsers cardanouser' >> /etc/ssh/sshd_config
ufw allow proto tcp from any to any port 6682
systemctl restart sshd
systemctl status sshd
su cardanouser
sudo apt install libpam-google-authenticator
google-authenticator #(press Y for all, scan the QR and save the codes)
sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config
sudo systemctl restart ssh
echo '#One-time authentication via Google Authenticator' >> /etc/pam.d/sshd
echo 'auth required pam_google_authenticator.so' >> /etc/pam.d/sshd
sudo systemctl restart ssh 
sudo apt install fail2ban
sudo systemctl status fail2ban 
```

## Upgrading
The following is the upgrade to Alonzo. It is a required upgrade. In my example I am upgrading from 1.27.0 to 1.29.0
```
sudo su
systemctl stop cnode
apt update && sudo apt full-upgrade -y
reboot
su cardanouser
cd "$HOME/tmp"
sudo su
systemctl stop cnode
wget https://github.com/canad1an/cardano-stake-pool/raw/master/files/alonzo.json
mv alonzo.json /opt/cardano/cnode/files/alonzo.json
wget https://github.com/canad1an/cardano-stake-pool/raw/master/files/cardano-cli-1.29.0
mv cardano-cli-1.29.0 cardano-cli
chmod +x cardano-cli
mv /usr/local/bin/cardano-cli /usr/local/bin/cardano-cli.bak
mv cardano-cli /usr/local/bin/
wget https://github.com/canad1an/cardano-stake-pool/raw/master/files/cardano-node-1.29.0
mv cardano-node-1.29.0 cardano-node
chmod +x cardano-node
mv /usr/local/bin/cardano-node /usr/local/bin/cardano-node.bak
mv cardano-node /usr/local/bin/
cd /opt/cardano/cnode/files/
nano config.json ### Add the following lines to the config.json file
  "AlonzoGenesisFile": "alonzo.json",
  "AlonzoGenesisHash": "7e94a15f55d1e82d10f09203fa1d40f8eede58fd8066542cf6566008068ed874",
systemctl start cnode
```

1.29.0 to 1.30.1
```
sudo su
systemctl stop cnode
apt update && sudo apt full-upgrade -y
reboot
su cardanouser
cd "$HOME/tmp"
sudo su
systemctl stop cnode
wget https://github.com/canad1an/cardano-stake-pool/raw/master/files/cardano-cli-1.30.1
mv cardano-cli-1.30.1 cardano-cli
chmod +x cardano-cli
mv /usr/local/bin/cardano-cli /usr/local/bin/cardano-cli.bak
mv cardano-cli /usr/local/bin/
wget https://github.com/canad1an/cardano-stake-pool/raw/master/files/cardano-node-1.30.1
mv cardano-node-1.30.1 cardano-node
chmod +x cardano-node
mv /usr/local/bin/cardano-node /usr/local/bin/cardano-node.bak
mv cardano-node /usr/local/bin/
systemctl start cnode
```

1.30.1 to 1.31.0
```
sudo su
systemctl stop cnode
apt update && sudo apt full-upgrade -y
reboot
su cardanouser
cd "$HOME/tmp"
sudo su
systemctl stop cnode
wget https://github.com/canad1an/cardano-stake-pool/raw/master/files/cardano-cli-1.31.0
mv cardano-cli-1.31.0 cardano-cli
chmod +x cardano-cli
mv /usr/local/bin/cardano-cli /usr/local/bin/cardano-cli.bak
mv cardano-cli /usr/local/bin/
wget https://github.com/canad1an/cardano-stake-pool/raw/master/files/cardano-node-1.31.0
mv cardano-node-1.31.0 cardano-node
chmod +x cardano-node
mv /usr/local/bin/cardano-node /usr/local/bin/cardano-node.bak
mv cardano-node /usr/local/bin/
systemctl start cnode
```

## OPTIONAL - Installing CNCLI for leaderlogs
This is completely optional. It is definitely useful though if you intend on seeing any future blocks your BP will produce.
```
https://docs.armada-alliance.com/learn/intermediate-guide/leader-logs
```

## OPTIONAL - Running a Web Server
This is completely optional. If you would like to install a simple webserver for your pool, follow these steps on any of the relays, or on a new raspberry pi.
```
su cardanouser
sudo apt install apache2 -y
sudo ufw allow "Apache Full"
sudo ufw allow 'Apache Secure'
sudo rm /etc/apache2/sites-enabled/000-default.conf
cat <<-EOF > /etc/apache2/sites-available/YOURDOMAINNAME.conf
<VirtualHost *:80>
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/html/YOURDOMAINNAME
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
        ServerName YOURDOMAINNAME
        ServerAlias www.YOURDOMAINNAME
        <Directory /var/www/webhost>
           Allowoverride all
        </Directory>
</VirtualHost>
EOF
sudo su
echo 'ServerName 127.0.0.1' >> /etc/apache2/apache2.conf
mkdir /var/www/html/YOURDOMAINNAME
chown -R www-data: /var/www/html/
a2ensite YOURDOMAINNAME
systemctl reload apache2
apt install certbot python3-certbot-apache -y
certbot -d YOURDOMAINNAME #Enter your email, then select A, then N, then 2
```

## OPTIONAL - Setting up Prometheus and Grafana on your webserver
This is completely optional. If you would like to install a simple webserver for your pool, follow these steps on any of the relays, or on a new raspberry pi. (I would recommend setting this up on an separate pi, for added security)
```
sudo su
groupadd --system prometheus
useradd -s /sbin/nologin --system -g prometheus prometheus
mkdir /var/lib/prometheus
for i in rules rules.d files_sd; do sudo mkdir -p /etc/prometheus/${i}; done
ls /var/lib/prometheus/
mkdir -p /tmp/prometheus && cd /tmp/prometheus
curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest   | grep browser_download_url   | grep linux-armv7   | cut -d '"' -f 4   | wget -qi -
tar xvf prometheus*.tar.gz
cd prometheus*/
mv prometheus promtool /usr/local/bin/
mv prometheus.yml  /etc/prometheus/prometheus.yml
mv consoles/ console_libraries/ /etc/prometheus/
sudo tee /etc/prometheus/prometheus.yml<<EOF
# my global config
global:
  scrape_interval:     15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
  # scrape_timeout is set to the global default (10s).

# Alertmanager configuration
alerting:
  alertmanagers:
  - static_configs:
    - targets:
      # - alertmanager:9093

# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  - job_name: 'relay-1' # To scrape data from the cardano node
    scrape_interval: 5s
    static_configs:
      - targets: ['10.10.10.10:12798']
        labels:
          instance: "relay1"
  - job_name: 'node-relay-1' # To scrape data from a node exporter to monitor your linux host metrics.
    scrape_interval: 5s
    static_configs:
      - targets: ['10.10.10.10:9100']
        labels:
          instance: "relay1"
EOF
sudo tee /etc/systemd/system/prometheus.service<<EOF
[Unit]
Description=Prometheus
Documentation=https://prometheus.io/docs/introduction/overview/
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=prometheus
Group=prometheus
ExecReload=/bin/kill -HUP \$MAINPID
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries \
  --web.listen-address=0.0.0.0:9090 \
  --web.external-url=

SyslogIdentifier=prometheus
Restart=always

[Install]
WantedBy=multi-user.target
EOF
for i in rules rules.d files_sd; do sudo chown -R prometheus:prometheus /etc/prometheus/${i}; done
for i in rules rules.d files_sd; do sudo chmod -R 775 /etc/prometheus/${i}; done
sudo chown -R prometheus:prometheus /var/lib/prometheus/
sudo systemctl daemon-reload
sudo systemctl start prometheus
sudo systemctl enable prometheus
systemctl status prometheus
sudo wget -q -O - https://packages.grafana.com/gpg.key | apt-key add -
sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
sudo apt update
sudo apt-get install grafana -y
sudo systemctl start grafana-server
sudo systemctl enable grafana-server
sudo ufw allow proto tcp from any to any port 3000
```

Add this to any of the relays/producer that you would like to allow metrics from:
```
sudo ufw allow proto tcp from 192.168.2.13 to any port 9100
sudo ufw allow proto tcp from 192.168.2.13 to any port 12798
```

## Credits
Big thanks to all the guides that I used to setup my RP staking pool. I grabbed a little bit from quite a few places, so i'll try and link them all here.
* https://www.raspberrypi.org/documentation/hardware/raspberrypi/booteeprom.md
* https://forum.cardano.org/t/how-to-set-up-a-pool-in-a-few-minutes-and-register-using-cntools/48767
* https://github.com/alessandrokonrad/Pi-Pool
* https://www.tomshardware.com/how-to/boot-raspberry-pi-4-usb
* https://www.raspberrypi.org/documentation/configuration/wireless/headless.md
