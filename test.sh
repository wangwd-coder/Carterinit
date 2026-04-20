#! /bin/bash
set -e

cd ~/Desktop/NV
sudo chmod +x *.sh
./3dview.sh
./2dview.sh

cd /opt/nvidia/nova/tools
./run_nova_tests.sh
argus_camera --module=3

ip a
