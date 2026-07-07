#! /bin/bash
set -e

function log() {
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1"
}

if [ -d ~/Desktop/NV ]; then
    cd ~/Desktop/NV
    sudo chmod +x *.sh
fi

# 雷达视图启动暂时禁用
# ./3dview.sh
# ./2dview.sh

if [ -f /opt/ros/humble/setup.bash ]; then
    source /opt/ros/humble/setup.bash
    log "ROS2 topic list"
    ros2 topic list
else
    log "未找到 /opt/ros/humble/setup.bash,跳过 ROS2 测试"
fi

if [ -x /opt/nvidia/nova/tools/run_nova_tests.sh ]; then
    log "运行 Nova 测试"
    cd /opt/nvidia/nova/tools
    ./run_nova_tests.sh
else
    log "未找到 /opt/nvidia/nova/tools/run_nova_tests.sh,跳过 Nova 测试"
fi

log "检查视频设备"
ls /dev/video* 2>/dev/null || log "未找到 /dev/video*"

if command -v argus_camera >/dev/null 2>&1; then
    log "运行 argus_camera --module=3"
    argus_camera --module=3
elif [ -x /opt/nvidia/nova/tools/argus_camera ]; then
    log "运行 /opt/nvidia/nova/tools/argus_camera --module=3"
    /opt/nvidia/nova/tools/argus_camera --module=3
else
    log "未找到 argus_camera,跳过 Argus 摄像头测试"
fi

log "网络信息"
ip a
