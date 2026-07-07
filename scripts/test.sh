#! /bin/bash
set -u

ROS2_VERSION="${ROS2_VERSION:-humble}"

function log() {
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1"
}

if [ -f "/opt/ros/$ROS2_VERSION/setup.bash" ]; then
    source "/opt/ros/$ROS2_VERSION/setup.bash"
    log "ROS2 topic list"
    ros2 topic list || log "ros2 topic list 执行失败"
else
    log "未找到 /opt/ros/$ROS2_VERSION/setup.bash,跳过 ROS2 测试"
fi

if [ -x /opt/nvidia/nova/tools/run_nova_tests.sh ]; then
    log "运行 Nova 测试"
    (cd /opt/nvidia/nova/tools && ./run_nova_tests.sh) || log "Nova 测试未全部通过"
else
    log "未找到 /opt/nvidia/nova/tools/run_nova_tests.sh,跳过 Nova 测试"
fi

log "检查视频设备"
ls /dev/video* 2>/dev/null || log "未找到 /dev/video*"
ls /dev/media* 2>/dev/null || log "未找到 /dev/media*"

if command -v argus_camera >/dev/null 2>&1; then
    log "运行 argus_camera --module=3"
    argus_camera --module=3 || log "argus_camera 执行失败"
elif [ -x /opt/nvidia/nova/tools/argus_camera ]; then
    log "运行 /opt/nvidia/nova/tools/argus_camera --module=3"
    /opt/nvidia/nova/tools/argus_camera --module=3 || log "argus_camera 执行失败"
else
    log "未找到 argus_camera,跳过 Argus 摄像头测试"
fi

if command -v media-ctl >/dev/null 2>&1; then
    log "media-ctl 相机拓扑摘要"
    media-ctl -p | grep -iE "ar0234|owl|hawk|video|entity" || true
fi

log "网络信息"
ip a
