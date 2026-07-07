#! /bin/bash
set -euo pipefail

DESKTOP_DIR="${DESKTOP_DIR:-$HOME/Desktop}"
if [ -z "${ROS2_VERSION:-}" ]; then
    if [ -f /opt/ros/humble/setup.bash ]; then
        ROS2_VERSION="humble"
    elif [ -f /opt/ros/foxy/setup.bash ]; then
        ROS2_VERSION="foxy"
    else
        ROS2_VERSION="humble"
    fi
fi

cd "$DESKTOP_DIR/2D-Lidar"
source "/opt/ros/$ROS2_VERSION/setup.bash"
source ./install/setup.bash
ros2 launch sllidar_ros2 view_sllidar_s2e_launch.py
