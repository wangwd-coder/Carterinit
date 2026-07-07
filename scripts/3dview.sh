#! /bin/bash
set -euo pipefail

DESKTOP_DIR="${DESKTOP_DIR:-$HOME/Desktop}"
ROS2_VERSION="${ROS2_VERSION:-humble}"

cd "$DESKTOP_DIR/3D-Lidar"
source "/opt/ros/$ROS2_VERSION/setup.bash"
source install/local_setup.bash
ros2 launch hesai_lidar hesai_lidar_launch.py
