# Carterinit

Nova Carter 现场辅助初始化工程。这个仓库主要负责基础环境、ROS2、雷达驱动部署、常用测试脚本和离线资源管理；相机 HAWK/OWL、Nova DTB、PTP/NVPPS 等整车 BSP 初始化仍建议使用 NVIDIA 官方 `nova-orin-init` 或旧系统上的 `nova-carter-init`。

## 目录结构

```text
.
├── new.sh                    # 一键入口
├── test.sh                   # 兼容入口,调用 scripts/test.sh
├── 2dview.sh                 # 兼容入口,启动 2D 雷达视图
├── 3dview.sh                 # 兼容入口,启动 3D 雷达视图
├── configs/
│   ├── apt/                  # 可选 apt sources.list
│   ├── launch/               # 雷达 launch 文件
│   └── rviz/                 # RViz 配置
├── packages/                 # 离线 deb/tar/zip 包
├── scripts/                  # 实际脚本实现
├── vendor/                   # 第三方 SDK、固件工具、Clash
└── docs/                     # 刷机等文档
```

## 一键运行

默认一键流程只做低风险步骤：

```bash
cd ~/Desktop/Carterinit
chmod +x *.sh scripts/*.sh
./new.sh
```

默认会执行：

```text
禁用 IPv6
同步工程到 ~/Desktop/NV
安装基础工具
按系统版本安装 ROS2：Ubuntu 20.04 使用 Foxy，Ubuntu 22.04 使用 Humble
跳过 apt sources.list 替换
跳过 LED 固件刷写
跳过底盘固件升级
跳过雷达仓库克隆和编译
跳过安装后测试
```

日志位置：

```bash
/tmp/carterinit-install.log
```

## 常用开关

开启 2D 雷达驱动部署：

```bash
ENABLE_LIDAR=true ./new.sh
```

同时开启 3D Hesai 雷达 ROS 包部署：

```bash
ENABLE_LIDAR=true ENABLE_HESAI_3D=true ./new.sh
```

安装后自动跑测试：

```bash
RUN_TEST_AFTER_INSTALL=true ./new.sh
```

替换 `/etc/apt/sources.list`，默认关闭，确需使用时再开：

```bash
REPLACE_APT_SOURCES=true ./new.sh
```

刷写 LED 固件，默认关闭：

```bash
ENABLE_LED_FIRMWARE=true ./new.sh
```

升级底盘固件，默认关闭：

```bash
ENABLE_CHASSIS_FIRMWARE=true ./new.sh
```

## 测试

```bash
./test.sh
```

测试脚本会尽量跑完所有检查，即使某一项失败也会继续输出后续信息。主要检查：

```text
ROS2 topic list
Nova preflight checker/run_nova_tests.sh
/dev/video* 和 /dev/media*
Argus 摄像头
media-ctl 相机拓扑摘要
网络信息
```

## 雷达视图

2D 雷达：

```bash
./2dview.sh
```

3D 雷达：

```bash
./3dview.sh
```

两个脚本默认使用：

```text
Ubuntu 20.04 自动使用 ROS2 Foxy
Ubuntu 22.04 自动使用 ROS2 Humble
DESKTOP_DIR=~/Desktop
```

如需覆盖：

```bash
ROS2_VERSION=foxy DESKTOP_DIR=/home/nvidia/Desktop ./2dview.sh
```

## Nova 初始化说明

JetPack 6.x 推荐使用 NVIDIA 官方：

```bash
sudo apt install nova-orin-init
```

安装时选择：

```text
nova-carter
```

旧包 `nova-carter-init_1.1.0-1_arm64.deb` 依赖 JetPack 5.x，JetPack 6.2 上默认不要安装。本仓库的旧包安装脚本默认跳过，只有显式开启时才会安装：

```bash
ENABLE_NOVA_CARTER_INIT=true ./install_novainit.sh
```

## 注意

- `new.sh` 不再默认替换系统 apt 源。
- 雷达和底盘固件默认禁用，避免误操作硬件。
- 工程会同步到 `~/Desktop/NV`，便于现场统一路径管理。
- 相机 HAWK/OWL 的 `/dev/video*`、DTB/overlay、Argus 问题不由本仓库单独解决，优先检查 `nova-orin-init` 或对应 JetPack 版本的相机驱动包。
