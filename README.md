# Run a Cardano Stake Pool on a Raspberry Pi 4

This guide will take you through every step required to create a cardano stake pool using just your Raspberri Pi. Some parts at the beginning are manual, like flashing the ssd and microsd. Then some major sections like installing the prereqs and building the cardano node, are all automated. This guide is intended for running a relay on 1 raspberry pi, and a separate raspberry pi for the producer. It is technically possibly to run them all together using docker, however for security and reliability, I have deployed them separately. 

## Credits
Hey guys as you're setting up your own pools please consider delegating your stake to my solar powered raspberry pi project: http://solarcardano.com/
Ticker: SOLRP
https://pooltool.io/pool/9728b10a926c048af938e5c52053319db5be921e8b698842c3afd3cc/
And as always, reach out to me if you have any questions!

## Required Hardware
```
* 2 8GB Raspberry Pi 4 (1 for the relay, 1 for the producer)
* SSD 500GB (256GB should be fine, but 500GB gives plenty of room for expansion)
```

## Getting Started: Flashing the images
To get started we need to flash the microsd with Raspberry Pi OS, and we need to flash the ssd with ubuntu 20. After we get the SSD setup as primary boot, we won't need the microsd.

```
1. Download the Raspberry Pi Imager: https://www.raspberrypi.org/software/
1. Insert the microsd into your PC/Mac
1. Select the OS and the SD Card and Write the image (Tutorial: https://www.youtube.com/watch?v=J024soVgEeM)
	1. Microsd: Raspberry Pi OS
	1. SSD: Ubuntu 20.01.2 ARM64 (Direct download: https://ubuntu.com/download/raspberry-pi/thank-you?version=20.04.2&architecture=server-arm64+raspi)
1. After the microsd is flashed, insert it into the raspberry Pi and power on the device.
```
