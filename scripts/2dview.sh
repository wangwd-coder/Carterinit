#! /bin/bash
set -euo pipefail

DESKTOP_DIR="${DESKTOP_DIR:-$HOME/Desktop}"
ROS2_VERSION="${ROS2_VERSION:-humble}"

cd "$DESKTOP_DIR/2D-Lidar"
source "/opt/ros/$ROS2_VERSION/setup.bash"
source ./install/setup.bash
ros2 launch sllidar_ros2 view_sllidar_s2e_launch.py
