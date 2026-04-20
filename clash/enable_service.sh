#!/bin/bash

cd $(dirname $0)

sudo rm /etc/systemd/system/clash.service
sudo cp service/clash.service  /etc/systemd/system/

sudo systemctl daemon-reload
sudo systemctl start clash.service
sudo systemctl enable clash.service
