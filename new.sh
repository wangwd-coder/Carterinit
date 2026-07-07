#!/bin/bash
set -euo pipefail

if [ -n "${SUDO_USER:-}" ]; then
    export HOME="$(eval echo "~$SUDO_USER")"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/configs"
PACKAGE_DIR="$SCRIPT_DIR/packages"
VENDOR_DIR="$SCRIPT_DIR/vendor"
DESKTOP_DIR="${DESKTOP_DIR:-$HOME/Desktop}"
STAGING_DIR="${STAGING_DIR:-$DESKTOP_DIR/NV}"
LOG_FILE="${LOG_FILE:-/tmp/carterinit-install.log}"

UBUNTU_CODENAME="${UBUNTU_CODENAME:-$(. /etc/os-release && echo "${VERSION_CODENAME:-}")}"
if [ -z "$UBUNTU_CODENAME" ] && command -v lsb_release >/dev/null 2>&1; then
    UBUNTU_CODENAME="$(lsb_release -sc)"
fi

if [ -z "${ROS2_VERSION:-}" ]; then
    case "$UBUNTU_CODENAME" in
        focal) ROS2_VERSION="foxy" ;;
        jammy) ROS2_VERSION="humble" ;;
        *) ROS2_VERSION="humble" ;;
    esac
fi

# 默认一键流程只做基础环境。需要额外动作时通过环境变量开启。
RUN_STAGE_PROJECT="${RUN_STAGE_PROJECT:-true}"
RUN_INSTALL_TOOLS="${RUN_INSTALL_TOOLS:-true}"
RUN_INSTALL_ROS2="${RUN_INSTALL_ROS2:-true}"
RUN_TEST_AFTER_INSTALL="${RUN_TEST_AFTER_INSTALL:-false}"
REPLACE_APT_SOURCES="${REPLACE_APT_SOURCES:-false}"
ENABLE_LIDAR="${ENABLE_LIDAR:-false}"
ENABLE_HESAI_3D="${ENABLE_HESAI_3D:-false}"
ENABLE_LED_FIRMWARE="${ENABLE_LED_FIRMWARE:-false}"
ENABLE_CHASSIS_FIRMWARE="${ENABLE_CHASSIS_FIRMWARE:-false}"

: >"$LOG_FILE"

function log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") $*" | tee -a "$LOG_FILE"
}

function is_true() {
    [ "${1:-false}" = "true" ]
}

function require_file() {
    if [ ! -e "$1" ]; then
        log "缺少文件: $1"
        exit 1
    fi
}

function stage_project() {
    log "同步工程到 $STAGING_DIR"

    if [ "$SCRIPT_DIR" = "$STAGING_DIR" ]; then
        log "当前目录已经是 $STAGING_DIR,跳过同步"
        return
    fi

    rm -rf "$STAGING_DIR"
    mkdir -p "$STAGING_DIR"
    (cd "$SCRIPT_DIR" && tar --exclude=.git -cf - .) | (cd "$STAGING_DIR" && tar -xf -)
    find "$STAGING_DIR" -maxdepth 2 -type f -name "*.sh" -exec chmod +x {} +
}

function configure_apt_sources() {
    if ! is_true "$REPLACE_APT_SOURCES"; then
        log "APT sources.list 替换已禁用,跳过该步骤"
        return
    fi

    require_file "$CONFIG_DIR/apt/sources.list"
    local backup="/etc/apt/sources.list.bak.$(date +%Y%m%d%H%M%S)"
    log "备份 /etc/apt/sources.list 到 $backup"
    sudo cp /etc/apt/sources.list "$backup"
    sudo cp "$CONFIG_DIR/apt/sources.list" /etc/apt/sources.list
    sudo apt-get update
}

function install_tools() {
    log "安装基础工具"
    sudo apt update
    sudo apt install -y \
        build-essential cmake curl git make openssh-client unzip \
        libboost-dev libpcap-dev libpcl-dev libprotobuf-dev libyaml-cpp-dev \
        protobuf-compiler \
        python3-pip python3-setuptools python3-venv
    log "基础工具安装完成"
}

function install_ros2() {
    if [ -e "/opt/ros/$ROS2_VERSION/setup.bash" ]; then
        log "ROS2 $ROS2_VERSION 已安装,跳过该步骤"
        return
    fi

    log "安装 ROS2 $ROS2_VERSION"
    sudo apt update
    sudo apt install -y curl gnupg lsb-release

    sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
        -o /usr/share/keyrings/ros-archive-keyring.gpg

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(lsb_release -sc) main" |
        sudo tee /etc/apt/sources.list.d/ros2.list >/dev/null

    sudo apt update
    sudo apt install -y \
        "ros-$ROS2_VERSION-desktop" \
        python3-argcomplete python3-colcon-common-extensions python3-lark \
        python3-vcstool
    pip3 install -U argcomplete || log "pip argcomplete 更新失败,继续后续流程"
    log "ROS2 $ROS2_VERSION 安装完成"
}

function clone_or_update() {
    local url="$1"
    local dir="$2"

    if [ -d "$dir/.git" ]; then
        log "更新 $dir"
        git -C "$dir" pull --ff-only
    else
        log "克隆 $url 到 $dir"
        git clone "$url" "$dir"
    fi
}

function clone_lidar_repos() {
    if ! is_true "$ENABLE_LIDAR"; then
        log "雷达仓库克隆已禁用,跳过该步骤"
        return
    fi

    mkdir -p "$DESKTOP_DIR/2D-Lidar/src"
    clone_or_update https://github.com/HesaiTechnology/HesaiLidar_General_SDK.git "$DESKTOP_DIR/HesaiLidar_General_SDK"
    clone_or_update https://github.com/Slamtec/rplidar_sdk.git "$DESKTOP_DIR/rplidar_sdk"
    clone_or_update https://github.com/Slamtec/sllidar_ros2.git "$DESKTOP_DIR/2D-Lidar/src/sllidar_ros2"
}

function compile_lidar_drivers() {
    if ! is_true "$ENABLE_LIDAR"; then
        log "雷达驱动编译已禁用,跳过该步骤"
        return
    fi

    require_file "/opt/ros/$ROS2_VERSION/setup.bash"
    source "/opt/ros/$ROS2_VERSION/setup.bash"

    log "编译 2D 雷达 rplidar_sdk"
    make -C "$DESKTOP_DIR/rplidar_sdk"

    log "配置并编译 2D 雷达 ROS2 包"
    mkdir -p "$DESKTOP_DIR/2D-Lidar/src/sllidar_ros2/rviz" "$DESKTOP_DIR/2D-Lidar/src/sllidar_ros2/launch"
    cp "$CONFIG_DIR/rviz/sllidar_ros2_dual.rviz" "$DESKTOP_DIR/2D-Lidar/src/sllidar_ros2/rviz/"
    cp "$CONFIG_DIR/launch/view_sllidar_s2e_launch.py" "$DESKTOP_DIR/2D-Lidar/src/sllidar_ros2/launch/"
    (cd "$DESKTOP_DIR/2D-Lidar" && colcon build --symlink-install)

    if is_true "$ENABLE_HESAI_3D"; then
        log "编译 3D 雷达 SDK"
        mkdir -p "$DESKTOP_DIR/HesaiLidar_General_SDK/build"
        (cd "$DESKTOP_DIR/HesaiLidar_General_SDK/build" && cmake .. && make -j"$(nproc)")

        log "配置并编译 3D 雷达 ROS2 包"
        mkdir -p "$DESKTOP_DIR/3D-Lidar/src"
        cp "$PACKAGE_DIR/HesaiLidar_General_ROS-ROS2.zip" "$DESKTOP_DIR/3D-Lidar/src/"
        (
            cd "$DESKTOP_DIR/3D-Lidar/src"
            rm -rf HesaiLidar_General_ROS-ROS2
            unzip -q HesaiLidar_General_ROS-ROS2.zip
            rm -f HesaiLidar_General_ROS-ROS2.zip
            mkdir -p HesaiLidar_General_ROS-ROS2/rviz2 HesaiLidar_General_ROS-ROS2/launch
            cp "$CONFIG_DIR/rviz/default.rviz" HesaiLidar_General_ROS-ROS2/rviz2/
            cp "$CONFIG_DIR/launch/hesai_lidar_launch.py" HesaiLidar_General_ROS-ROS2/launch/
        )
        (cd "$DESKTOP_DIR/3D-Lidar" && colcon build --symlink-install)
    fi
}

function flash_led_firmware() {
    if ! is_true "$ENABLE_LED_FIRMWARE"; then
        log "LED 固件刷写已禁用,跳过该步骤"
        return
    fi

    log "刷写 LED 固件"
    require_file "$VENDOR_DIR/LED/carter-v2.4-led-main/bossac_armv8"
    require_file "$VENDOR_DIR/LED/firmware.bin"
    (
        cd "$VENDOR_DIR/LED/carter-v2.4-led-main"
        sudo chmod +x bossac_armv8
        sudo ./bossac_armv8 -a -p /dev/ttyACM0
        sudo ./bossac_armv8 -p /dev/ttyACM0 -w -v -R -o 0x2000 ../firmware.bin
    )
}

function update_chassis_firmware() {
    if ! is_true "$ENABLE_CHASSIS_FIRMWARE"; then
        log "底盘固件拷贝和升级已禁用,跳过该步骤"
        return
    fi

    log "升级底盘固件"
    require_file "$VENDOR_DIR/RMP220-SDK-2.0.0/LibAPI/exec/ctrl_arm64-v8a"
    require_file "$VENDOR_DIR/RMP220-SDK-2.0.0/LibAPI/exec/Segway_RMP_Init.sh"

    sudo mkdir -p /sdcard/firmware
    sudo cp "$VENDOR_DIR"/RMP220-SDK-2.0.0/Firmware/V1/*.bin /sdcard/firmware/
    sudo chmod +x "$VENDOR_DIR"/RMP220-SDK-2.0.0/LibAPI/exec/{ctrl_arm64-v8a,Segway_RMP_Init.sh}
    bash "$VENDOR_DIR/RMP220-SDK-2.0.0/LibAPI/exec/Segway_RMP_Init.sh"

    (
        cd "$VENDOR_DIR/RMP220-SDK-2.0.0/LibAPI/exec"
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
    )
}

function run_tests() {
    if ! is_true "$RUN_TEST_AFTER_INSTALL"; then
        log "安装后测试已禁用,跳过该步骤"
        return
    fi

    log "运行 test.sh"
    "$SCRIPT_DIR/scripts/test.sh" || log "test.sh 返回非零状态,请查看上方输出"
}

function main() {
    sudo -v

    log "开始 Carterinit 一键流程"
    log "配置: UBUNTU_CODENAME=$UBUNTU_CODENAME ROS2_VERSION=$ROS2_VERSION ENABLE_LIDAR=$ENABLE_LIDAR ENABLE_HESAI_3D=$ENABLE_HESAI_3D"

    sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
    sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1
    sudo sysctl -w net.ipv6.conf.lo.disable_ipv6=1

    if is_true "$RUN_STAGE_PROJECT"; then
        stage_project
    fi

    configure_apt_sources

    if is_true "$RUN_INSTALL_TOOLS"; then
        install_tools
    fi

    if is_true "$RUN_INSTALL_ROS2"; then
        install_ros2
    fi

    flash_led_firmware
    update_chassis_firmware
    clone_lidar_repos
    compile_lidar_drivers
    run_tests

    log "Carterinit 一键流程完成,日志: $LOG_FILE"
}

main "$@"
