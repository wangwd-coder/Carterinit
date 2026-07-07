#! /bin/bash
set -u

if [ -z "${ROS2_VERSION:-}" ]; then
    if [ -f /opt/ros/humble/setup.bash ]; then
        ROS2_VERSION="humble"
    elif [ -f /opt/ros/foxy/setup.bash ]; then
        ROS2_VERSION="foxy"
    else
        ROS2_VERSION="humble"
    fi
fi

function log() {
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1"
}

if [ -f "/opt/ros/$ROS2_VERSION/setup.bash" ]; then
    source "/opt/ros/$ROS2_VERSION/setup.bash"
    log "ROS2 topic list"
    ros2 topic list || log "ros2 topic list failed"
else
    log "/opt/ros/$ROS2_VERSION/setup.bash was not found; skipping ROS2 test"
fi

if [ -x /opt/nvidia/nova/tools/run_nova_tests.sh ]; then
    log "Running Nova tests"
    (cd /opt/nvidia/nova/tools && ./run_nova_tests.sh) || log "Nova tests did not all pass"
else
    log "/opt/nvidia/nova/tools/run_nova_tests.sh was not found; skipping Nova tests"
fi

log "Checking video devices"
ls /dev/video* 2>/dev/null || log "No /dev/video* devices found"
ls /dev/media* 2>/dev/null || log "No /dev/media* devices found"

if command -v argus_camera >/dev/null 2>&1; then
    log "Running argus_camera --module=3"
    argus_camera --module=3 || log "argus_camera failed"
elif [ -x /opt/nvidia/nova/tools/argus_camera ]; then
    log "Running /opt/nvidia/nova/tools/argus_camera --module=3"
    /opt/nvidia/nova/tools/argus_camera --module=3 || log "argus_camera failed"
else
    log "argus_camera was not found; skipping Argus camera test"
fi

if command -v media-ctl >/dev/null 2>&1; then
    log "media-ctl camera topology summary"
    media-ctl -p | grep -iE "ar0234|owl|hawk|video|entity" || true
fi

log "Network information"
ip a
