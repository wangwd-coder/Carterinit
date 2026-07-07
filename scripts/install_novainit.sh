#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.lo.disable_ipv6=1

# nova-carter-init_1.1.0-1_arm64.deb depends on JetPack 5.x and fails on JetPack 6.2.
# Run ENABLE_NOVA_CARTER_INIT=true ./install_novainit.sh only after confirming compatibility.
if [ "${ENABLE_NOVA_CARTER_INIT:-false}" = "true" ]; then
    sudo apt install "$ROOT_DIR/packages/nova-carter-init_1.1.0-1_arm64.deb"
else
    echo "Skipping legacy nova-carter-init package installation"
fi
