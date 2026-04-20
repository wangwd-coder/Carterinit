#! /bin/bash
set -e

cd /home/nvidia/Desktop/2D-Lidar
source ./install/setup.bash
source /opt/ros/foxy/setup.bash
ros2 launch sllidar_ros2 view_sllidar_s2e_launch.py
