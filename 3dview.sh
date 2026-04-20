#! /bin/bash
set -e

cd /home/nvidia/Desktop/3D-Lidar
source /opt/ros/foxy/setup.bash
source install/local_setup.bash
ros2 launch hesai_lidar hesai_lidar_launch.py
