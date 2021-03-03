# Run a Cardano Stake Pool on a Raspberry Pi 4

This guide will take you through every step required to create a cardano stake pool using just your Raspberri Pi. Some parts at the beginning are manual, like flashing the ssd and microsd. Then some major sections like installing the prereqs and building the cardano node, are all automated. This guide is intended for running a relay on 1 raspberry pi, and a separate raspberry pi for the producer. It is technically possibly to run them all together using docker, however for security and reliability, I have deployed them separately. 

## Credits
Hey guys as you're setting up your own pools please consider delegating your stake to my solar powered raspberry pi project: http://solarcardano.com/  
Ticker: SOLRP  
https://pooltool.io/pool/9728b10a926c048af938e5c52053319db5be921e8b698842c3afd3cc/  
And as always, reach out to me if you have any questions!

## Required Hardware
* 2 8GB Raspberry Pi 4 (1 for the relay, 1 for the producer)
* SSD 500GB (256GB should be fine, but 500GB gives plenty of room for expansion)


## Getting Started: Flashing the images
To get started we need to flash the microsd with Raspberry Pi OS, and we need to flash the ssd with ubuntu 20. After we get the SSD setup as primary boot, we won't need the microsd.

```
1. Download the Raspberry Pi Imager: https://www.raspberrypi.org/software/
2. Insert the microsd into your PC/Mac
3. Select the OS and the SD Card and Write the image (Tutorial: https://www.youtube.com/watch?v=J024soVgEeM)
	a. Microsd: Raspberry Pi OS
	b. SSD: Ubuntu 20.01.2 ARM64 (Direct download: https://ubuntu.com/download/raspberry-pi/thank-you?version=20.04.2&architecture=server-arm64+raspi)
4. Now we need to make the raspbian OS boot in headless mode so that you can ssh to the device, without having to setup a monitor, keyboard, mouse, etc.
	a. For headless setup, SSH can be enabled by placing a file named ssh, without any extension, onto the boot partition of the SD card from another computer. So literally just create a file called "ssh" in the boot partition, and you're done.
5. Make sure to connect an ethernet cable to your raspberry pi (if DHCP is configured, you should be able to get a local IP)
	a. If you would prefer to do a wireless setup, follow this doc. It will require adding a file to your rasbian (on the microsd, same as you did with the ssh) which you will do BEFORE you boot it on the raspberry pi: https://www.raspberrypi.org/documentation/configuration/wireless/headless.md
6. After the microsd is flashed, insert it into the raspberry Pi and power on the device.
```

## Upgrading firmware
After the raspberry Pi boots up, you should be able to ssh into the device. You'll need to look through your network config man to find the IP address that was assigned via DHCP.
Next step is to upgrade the firmware for our Raspberry Pi devices.  

Run on both the raspberry Pi devices to upgrade firmware:
```
sudo su
sudo apt update && sudo apt full-upgrade -y
sudo apt install rpi-eeprom
sudo rpi-eeprom-update -a
echo 'FIRMWARE_RELEASE_STATUS="stable"' > /etc/default/rpi-eeprom-update
sudo rpi-eeprom-update -d -f /lib/firmware/raspberrypi/bootloader/stable/pieeprom-2020-07-31.bin
reboot
```



