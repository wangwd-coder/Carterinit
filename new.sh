#!/bin/bash
# 设置退出时遇到错误自动退出
set -e

# 日志文件
LOG_FILE=/tmp/install.log

# 日志记录函数
function log() {
    echo $(date +"%Y-%m-%d %H:%M:%S") $1 | tee -a $LOG_FILE
}

# 清空日志文件
>$LOG_FILE

# 读取主机 IP (已不使用 SCP 远程拷贝，如无需可跳过)
# read -p "请输入主机 IP 地址:" HOST_IP

# 读取默认用户名
# read -p "请输入默认用户名:" DEFAULT_USER

# 读取默认密码
# read -s -p "请输入密码:" DEFAULT_PASSWORD
# echo

# ROS 版本
ROS1_VERSION="noetic"
ROS2_VERSION="foxy"

# ROS 密钥
ROSKEY="https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc"

# ROS 源
ROS1_REPO="http://packages.ros.org/ros/ubuntu"
ROS2_REPO="http://packages.ros.org/ros2/ubuntu"

# 安装 ROS 1
function install_ros1() {

    if [ -e "/opt/ros/$ROS1_VERSION" ]; then
        log "ROS $ROS1_VERSION 已安装,跳过该步骤"
        return
    fi

    log "开始安装 ROS $ROS1_VERSION"

    sudo apt update
    sudo sh -c "echo deb $ROS1_REPO $(lsb_release -sc) main > /etc/apt/sources.list.d/ros-latest.list"

    sudo apt install curl -y
    curl -s $ROSKEY | sudo apt-key add -

    sudo apt update
    sudo apt install ros-$ROS1_VERSION-desktop-full -y

    log "ROS $ROS1_VERSION 安装完成"
}

# 安装 ROS 2
function install_ros2() {

    if [ -e "/opt/ros/$ROS2_VERSION" ]; then
        log "ROS $ROS2_VERSION 已安装,跳过该步骤"
        return
    fi

    log "开始安装 ROS $ROS2_VERSION"

    cd ~/Desktop/NV/
    sudo chmod +x *.sh
    ./import_ros_key.sh

    sudo sh -c "echo deb $ROS2_REPO $(lsb_release -sc) main > /etc/apt/sources.list.d/ros2-latest.list"

    sudo apt update

    sudo apt install ros-foxy-desktop -y
    sudo apt install python3-pip python3-colcon-common-extensions python3-lark python3-setuptools python3-vcstool python3-argcomplete -y

    pip3 install -U argcomplete

    log "ROS $ROS2_VERSION 安装完成"

}

function install_tools() {

    # if [ -e "/usr/bin/sshpass" ]; then
    #     log "SSHPASS 已安装,跳过该步骤"
    #     return
    # fi

    log "开始安装基础工具"
    sudo apt update
    sudo apt install curl openssh-client libpcap-dev libyaml-cpp-dev libpcl-dev libboost-dev libprotobuf-dev protobuf-compiler -y

    log "基础工具安装完成"
}

# 克隆代码仓库
function clone_repos() {

    log "开始克隆代码仓库"

    # sudo rm -rf RMP220-SDK

    # git clone https://github.com/SegwayRoboticsSamples/RMP220-SDK.git
    cd ~/Desktop
    git clone https://github.com/HesaiTechnology/HesaiLidar_General_SDK.git
    git clone https://github.com/Slamtec/rplidar_sdk.git

    mkdir -p ~/Desktop/2D-Lidar/src && cd ~/Desktop/2D-Lidar/src

    git clone https://github.com/Slamtec/sllidar_ros2.git

    log "代码仓库克隆完成"
}

# 拷贝固件
function copy_firmware() {

    log "开始拷贝固件"
    sudo rm -rf ~/Desktop/3D-Lidar/ ~/Desktop/NV/ ~/Desktop/rplidar_sdk ~/Desktop/sllidar_ros2 ~/Desktop/2D-Lidar ~/Desktop/HesaiLidar_General_SDK

    mkdir -p ~/Desktop/{3D-Lidar,NV}/src

    # 从本地 Carterinit 目录拷贝文件（兼容 sudo 运行）
    if [ -n "$SUDO_USER" ]; then
        REAL_HOME=$(eval echo ~$SUDO_USER)
    else
        REAL_HOME=$HOME
    fi
    cp -r $REAL_HOME/Carterinit/* ~/Desktop/NV/

    cd ~/Desktop/NV/
    chmod +x *.sh
    # tar -xvf clash_arm64.tar

    # sudo rm -rf /opt/clash/
    # sudo mv clash /opt
    # cd /opt/clash/
    # sudo ./enable_service.sh
    # sudo systemctl restart clash.service
    # cd ~/Desktop/NV/

    # sudo dpkg -i nomachine_8.2.3_3_arm64.deb
    cd /etc/apt/
    sudo mv sources.list sources.list.bak
    sudo cp ~/Desktop/NV/sources.list .
    sudo apt-get update

    log "固件拷贝完成"
}

function iap_bin() {

    echo "开始刷写LED固件"

    cd ~/Desktop/NV/LED/carter-v2.4-led-main
    sudo chmod +x bossac_armv8
    sudo ./bossac_armv8 -a -p /dev/ttyACM0
    sudo ./bossac_armv8 -p /dev/ttyACM0 -w -v -R -o 0x2000 ../firmware.bin

    log "拷贝底盘固件"
    sudo mkdir -p /sdcard/firmware
    sudo cp ~/Desktop/NV/RMP220-SDK-2.0.0/Firmware/V1/*.bin /sdcard/firmware
    sudo chmod +x ~/Desktop/NV/RMP220-SDK-2.0.0/LibAPI/exec/{ctrl_arm64-v8a,Segway_RMP_Init.sh}
    bash ~/Desktop/NV/RMP220-SDK-2.0.0/LibAPI/exec/Segway_RMP_Init.sh

    log "开始升级"
    cd ~/Desktop/NV/RMP220-SDK-2.0.0/LibAPI/exec/
    central_output=$(./ctrl_arm64-v8a c -iap central)
    if [[ "$central_output" == *"Iap_success!"* ]]; then
        log "主控固件升级成功"
    else
        log "主控固件升级失败"
    fi

    motor_output=$(./ctrl_arm64-v8a c -iap motor)

    if [[ "$motor_output" == *"100"* ]]; then
        log "电机固件升级成功"
    else
        log "电机固件升级失败"
    fi
    # log "开始安装Nova-Carter-init"
    # cd ~/Desktop/NV/
    # sudo apt install ./nova-carter-init_1.1.0-1_arm64.deb -y

}

function compile_driver() {

    log "开始编译2D雷达驱动"

    cd ~/Desktop/rplidar_sdk && make

    log "开始编译2D雷达ROS包"

    source /opt/ros/foxy/setup.bash

    cp ~/Desktop/NV/sllidar_ros2_dual.rviz ~/Desktop/2D-Lidar/src/sllidar_ros2/rviz
    cp ~/Desktop/NV/view_sllidar_s2e_launch.py ~/Desktop/2D-Lidar/src/sllidar_ros2/launch

    cd ~/Desktop/2D-Lidar && colcon build --symlink-install

    log "开始编译3D雷达驱动"
    source /opt/ros/foxy/setup.bash
    cd ~/Desktop/HesaiLidar_General_SDK && mkdir build && cd build && cmake ..
    sudo ln -sf /usr/include/eigen3/Eigen /usr/include/Eigen
    make

    log "开始编译3D雷达ROS包"
    sudo mv ~/Desktop/NV/HesaiLidar_General_ROS-ROS2.zip ~/Desktop/3D-Lidar/src
    cd ~/Desktop/3D-Lidar/src && unzip HesaiLidar_General_ROS-ROS2.zip && rm -rf HesaiLidar_General_ROS-ROS2.zip
    mkdir -p ~/Desktop/3D-Lidar/src/HesaiLidar_General_ROS-ROS2/rviz2
    sudo cp ~/Desktop//NV/default.rviz ~/Desktop/3D-Lidar/src/HesaiLidar_General_ROS-ROS2/rviz2
    sudo cp ~/Desktop/NV/hesai_lidar_launch.py ~/Desktop/3D-Lidar/src/HesaiLidar_General_ROS-ROS2/launch

    cd ../ && colcon build --symlink-install

}

# 主函数
function main() {
    log "禁用IPv6"
    sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
    sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1
    sudo sysctl -w net.ipv6.conf.lo.disable_ipv6=1

    # sudo apt remove -y nova-carter-init
    #获取主机known_hosts
    # ssh-keyscan -H $HOST_IP >>~/.ssh/known_hosts

    copy_firmware
    install_tools
    # export http_proxy=http://127.0.0.1:1089
    # export https_proxy=http://127.0.0.1:1089

    # firefox
    iap_bin
    # install_ros1
    install_ros2
    clone_repos
    compile_driver

}

main
