set -e

sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.lo.disable_ipv6=1
export http_proxy=http://127.0.0.1:1089
export https_proxy=http://127.0.0.1:1089

latest_deb=$(find . -maxdepth 1 -name "nova-carter-init_*_arm64.deb" -print | sort -V | tail -n 1)

if [ -n "$latest_deb" ]; then
    echo "安装 $latest_deb"
    sudo apt install "$latest_deb"
else
    echo "未找到 nova-carter-init_*_arm64.deb"
    exit 1
fi
