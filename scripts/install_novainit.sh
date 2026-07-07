#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.lo.disable_ipv6=1

# nova-carter-init_1.1.0-1_arm64.deb 依赖 JetPack 5.x,JetPack 6.2 会安装失败。
# 如确认当前系统兼容该旧包,可执行 ENABLE_NOVA_CARTER_INIT=true ./install_novainit.sh
if [ "${ENABLE_NOVA_CARTER_INIT:-false}" = "true" ]; then
    sudo apt install "$ROOT_DIR/packages/nova-carter-init_1.1.0-1_arm64.deb"
else
    echo "跳过 nova-carter-init 旧包安装"
fi
