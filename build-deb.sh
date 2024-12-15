#!/usr/bin/env python3
kernelUrl=https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.12.5.tar.xz
# 专门针对 Github Action 制作的，适用于 GXDE 的内核工具工程
sudo sed -i "/deb-src/s/# //g" /etc/apt/sources.list
cd $(dirname $0)
rm -rfv build
mkdir build
# 安装依赖
sudo apt install -y aria2
sudo apt install -y wget xz-utils make gcc flex bison dpkg-dev bc rsync kmod cpio libssl-dev git lsb vim libelf-dev
# 解压源码包
wget $kernelUrl
tar -xf $(basename $kernelUrl)
mv */* . -v
# 拷贝配置文件
cp ../config .config

#
# disable DEBUG_INFO to speedup build
# scripts/config --disable DEBUG_INFO 
scripts/config --set-str SYSTEM_TRUSTED_KEYS ""
scripts/config --set-str SYSTEM_REVOCATION_KEYS ""
scripts/config --undefine DEBUG_INFO
scripts/config --undefine DEBUG_INFO_COMPRESSED
scripts/config --undefine DEBUG_INFO_REDUCED
scripts/config --undefine DEBUG_INFO_SPLIT
scripts/config --undefine GDB_SCRIPTS
scripts/config --disable DEBUG_INFO
scripts/config --set-val  DEBUG_INFO_DWARF5     n
scripts/config --set-val  DEBUG_INFO_NONE       y

CPU_CORES=$(($(grep -c processor < /proc/cpuinfo)*2))
sudo env DEBEMAIL="gfdgd xi <3025613752@qq.com>" make bindeb-pkg -j"$CPU_CORES"
sudo mv ../*.deb ../.. -v