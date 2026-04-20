# Nova Carter Init 工程说明

## 项目概述

本工程用于 Nova Carter/Segway RMP 设备初始化、固件拷贝、LED 固件刷写、ROS2 环境安装以及 2D/3D 雷达驱动编译部署。

工程基于以下组件：
- LED 固件工具：`LED/carter-v2.4-led-main`
- Segway RMP220 SDK：`RMP220-SDK-2.0.0`
- 2D 雷达 `sllidar_ros2`
- 3D 雷达 `HesaiLidar_General_ROS-ROS2`
- 根目录安装脚本 `new.sh`、`install_novainit.sh`

## 目录结构（关键部分）

- `new.sh`：主安装脚本，自动完成工程拷贝、工具安装、固件升级、ROS2 安装、仓库克隆和驱动编译。
- `install_novainit.sh`：备用安装脚本，可单独安装 ROS、基础工具、导入源、拷贝固件和驱动。
- `import_ros_key.sh`：导入 ROS 软件源公钥。
- `LED/carter-v2.4-led-main/`：LED BLE 固件刷写工具及相关源码。
- `RMP220-SDK-2.0.0/`：Segway RMP220 SDK 固件、库文件和控制程序。
- `default.rviz`：3D 雷达 RViz 配置文件。
- `sllidar_ros2_dual.rviz`：2D 雷达 RViz 配置文件。
- `hesai_lidar_launch.py`、`view_sllidar_s2e_launch.py`：雷达启动配置脚本。

## 运行前准备

1. 目标主机需为 Ubuntu/Debian 系统，并具备 `sudo` 权限。
2. 目标主机应能访问互联网，并可连接 ROS 软件源。
3. 目标主机推荐安装 `sshpass`，`new.sh` 会使用它进行文件拷贝。
4. 当前工作目录默认使用 `~/Desktop/NV/`，并会在 `~/Desktop/` 下创建或覆盖相关目录。
5. 本地仓库根目录下的 shell 脚本应具有执行权限：

```bash
cd /Users/wangweidong/Desktop/个人/test_weidong/NV/Carter_init
chmod +x *.sh
```

## `new.sh` 执行流程

`new.sh` 的主流程包括：

1. 禁用 IPv6：
   - `sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1`
   - `sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1`
   - `sudo sysctl -w net.ipv6.conf.lo.disable_ipv6=1`
2. `copy_firmware`：
   - 读取目标主机 IP、用户名、密码
   - 使用 `sshpass` 从目标主机拷贝 `~/Desktop/Code/test_weidong/NV/Carter_init/*` 到本机 `~/Desktop/NV/`
   - 解压 `clash_arm64.tar` 并启用 `clash` 服务
   - 复制并替换 `/etc/apt/sources.list`，更新 apt 源
3. `install_tools`：安装常用依赖工具和库：
   - `curl`, `openssh-client`, `libpcap-dev`, `libyaml-cpp-dev`, `libpcl-dev`, `libboost-dev`, `libprotobuf-dev`, `protobuf-compiler`
4. 设置代理环境：
   - `export http_proxy=http://127.0.0.1:1089`
   - `export https_proxy=http://127.0.0.1:1089`
5. `firefox`：脚本会直接调用 `firefox`，请确认系统已安装 Firefox 浏览器。
6. `iap_bin`：
   - 进入 `~/Desktop/NV/LED/carter-v2.4-led-main`
   - 运行 `bossac_armv8` 进行 LED 固件烧写
   - 拷贝主控和电机固件到 `/sdcard/firmware`
   - 执行 `Segway_RMP_Init.sh`
   - 使用 `ctrl_arm64-v8a` 进行主控和电机固件升级验证
7. `install_ros2`：安装 ROS2 Foxy，包含 `colcon` 等工具。
8. `clone_repos`：克隆以下仓库到 `~/Desktop/`：
   - `HesaiLidar_General_SDK`
   - `rplidar_sdk`
   - `sllidar_ros2`
9. `compile_driver`：
   - 编译 `rplidar_sdk`
   - 复制 2D 雷达 RViz 和 launch 文件，编译 `sllidar_ros2`
   - 编译 3D 雷达 SDK，解压 3D ROS 包，复制 RViz 和 launch 文件，构建 3D 雷达 ROS 包

## 重要注意事项

- `new.sh` 假设 `~/Desktop/NV/` 已存在且可写，如果已有旧数据可能被覆盖。
- `copy_firmware` 里会执行 `sudo rm -rf ~/Desktop/3D-Lidar/ ~/Desktop/NV/ ~/Desktop/rplidar_sdk ~/Desktop/sllidar_ros2 ~/Desktop/2D-Lidar ~/Desktop/HesaiLidar_General_SDK`，请谨慎使用。
- 脚本中会调用 `firefox`，若目标环境无 GUI 或未安装 Firefox 会失败。
- `install_ros2` 指定了 `ros-foxy-desktop`，仅在支持 Foxy 的 Ubuntu 版本上测试通过。
- 目标主机 `sources.list` 会被替换，为国内 ROS 源配置，若你需要恢复原源请提前备份。
- `import_ros_key.sh` 的功能是导入 ROS 公钥，若系统已无 `apt-key add` 支持，可改为新方式管理密钥。

## 单独使用说明

### `install_novainit.sh`

该脚本主要用于单独安装和部署：
- 禁用 IPv6
- 设置代理变量
- 安装 `nova-carter-init_1.1.0-1_arm64.deb`

它可作为 `new.sh` 的补充脚本，但与你的目标环境和 `.deb` 包版本有关。

### `import_ros_key.sh`

该脚本把 ROS 公钥写入 apt 密钥环，用于 ROS 源认证。如果系统不再支持 `apt-key`，请使用新的 `trusted.gpg.d` 方式导入公钥。

## 参考

- 根目录脚本已补齐说明，后续如果要进一步补充，可以把 `LED/` 和 `RMP220-SDK-2.0.0/` 内部 README 的关键命令摘录到根目录。
