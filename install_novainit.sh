set -e

sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.lo.disable_ipv6=1
export http_proxy=http://127.0.0.1:1089
export https_proxy=http://127.0.0.1:1089

sudo apt install ./nova-carter-init_1.1.0-1_arm64.deb
