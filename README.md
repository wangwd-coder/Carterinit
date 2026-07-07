# Carterinit

Field setup helper for Nova Carter. This repository manages base packages, ROS2, lidar driver deployment, test scripts, and local offline resources. Full vehicle BSP setup such as HAWK/OWL cameras, Nova DTB overlays, PTP, and NVPPS should still be handled by NVIDIA `nova-orin-init` or by the legacy `nova-carter-init` package on compatible JetPack 5.x systems.

## Layout

```text
.
├── new.sh                    # One-command setup entrypoint
├── test.sh                   # Compatibility wrapper for scripts/test.sh
├── 2dview.sh                 # Compatibility wrapper for the 2D lidar view
├── 3dview.sh                 # Compatibility wrapper for the 3D lidar view
├── configs/
│   ├── apt/                  # Optional apt sources.list
│   ├── launch/               # Lidar launch files
│   └── rviz/                 # RViz configs
├── packages/                 # Offline deb/tar/zip packages
├── scripts/                  # Script implementations
├── vendor/                   # Third-party SDKs, firmware tools, and Clash
└── docs/                     # Flashing and field notes
```

## One-Command Setup

The default flow only runs low-risk setup steps:

```bash
cd ~/Desktop/Carterinit
chmod +x *.sh scripts/*.sh
./new.sh
```

The default flow does this:

```text
Disable IPv6
Sync the project to ~/Desktop/NV
Install base tools
Install ROS2 by Ubuntu release: Foxy on Ubuntu 20.04, Humble on Ubuntu 22.04
Skip apt sources.list replacement
Skip LED firmware flashing
Skip chassis firmware update
Skip lidar repository cloning and build
Skip post-install tests
```

Log file:

```bash
/tmp/carterinit-install.log
```

## Common Switches

Enable 2D lidar driver deployment:

```bash
ENABLE_LIDAR=true ./new.sh
```

Enable both 2D lidar and 3D Hesai ROS package deployment:

```bash
ENABLE_LIDAR=true ENABLE_HESAI_3D=true ./new.sh
```

Run tests after installation:

```bash
RUN_TEST_AFTER_INSTALL=true ./new.sh
```

Replace `/etc/apt/sources.list`. This is disabled by default and should only be enabled when needed:

```bash
REPLACE_APT_SOURCES=true ./new.sh
```

Flash LED firmware. This is disabled by default:

```bash
ENABLE_LED_FIRMWARE=true ./new.sh
```

Update chassis firmware. This is disabled by default:

```bash
ENABLE_CHASSIS_FIRMWARE=true ./new.sh
```

## Tests

```bash
./test.sh
```

The test script tries to finish all checks even if one item fails. It checks:

```text
ROS2 topic list
Nova preflight checker/run_nova_tests.sh
/dev/video* and /dev/media*
Argus camera
media-ctl camera topology summary
Network information
```

## Lidar Views

2D lidar:

```bash
./2dview.sh
```

3D lidar:

```bash
./3dview.sh
```

The view scripts use these defaults:

```text
Ubuntu 20.04 automatically uses ROS2 Foxy
Ubuntu 22.04 automatically uses ROS2 Humble
DESKTOP_DIR=~/Desktop
```

Override when needed:

```bash
ROS2_VERSION=foxy DESKTOP_DIR=/home/nvidia/Desktop ./2dview.sh
```

## Nova Setup

For JetPack 6.x, use NVIDIA's official package:

```bash
sudo apt install nova-orin-init
```

Select this profile during installation:

```text
nova-carter
```

The legacy package `nova-carter-init_1.1.0-1_arm64.deb` depends on JetPack 5.x and should not be installed on JetPack 6.2 by default. This repository's legacy package wrapper skips it unless explicitly enabled:

```bash
ENABLE_NOVA_CARTER_INIT=true ./install_novainit.sh
```

## Notes

- `new.sh` no longer replaces system apt sources by default.
- Lidar and chassis firmware actions are disabled by default to avoid unintended hardware changes.
- The project is synced to `~/Desktop/NV` for consistent field paths.
- HAWK/OWL camera issues involving `/dev/video*`, DTB overlays, and Argus are not solved by this repository alone. Check `nova-orin-init` or the camera driver package that matches the JetPack version.
