# Carter LED Firmware

This is a basic LED firmware for the Adafruit Trinket M0 board used in Carter v2.4.

# Flashing
The firmware can be flashed from Jetson by using the `bossac` utility. Ensure the Trinket board is connected to a USB port of the Jetson.
The binary file will be generated in `.pio/build/adafruit_trinket_m0/firmware.bin`

Reset to bootloader and erase flash:

`sudo ./bossac -a -p /dev/ttyACM0`

Flash the firmware:

`sudo ./bossac -p /dev/ttyACM0 -w -v -R -o 0x2000 ./firmware.bin`

# Service
Service files must have execute permission.
Create the service file in `/etc/systemd/system/carter-LED.service`:

```
[Unit]
After=network.target
Before=shutdown.target

[Service]
RemainAfterExit=true
ExecStart=/usr/bin/NOVA/LED/LED_start.sh
ExecStop=/usr/bin/NOVA/LED/LED_stop.sh

[Install]
WantedBy=default.target
```

Contents of `/usr/bin/NOVA/LED/LED_start.sh`:

```
#!/bin/bash
chmod a+rw /dev/ttyACM0
echo -n "1" > /dev/ttyACM0
```

Contents of `/usr/bin/NOVA/LED/LED_stop.sh`:

```
#!/bin/bash
chmod a+rw /dev/ttyACM0
echo -n "0" > /dev/ttyACM0
```

Enable the service:

```
sudo systemctl daemon-reload
sudo systemctl enable carter-LED.service
```