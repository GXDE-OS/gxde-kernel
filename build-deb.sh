#!/usr/bin/env python3
kernelUrl=https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.12.10.tar.xz
# 专门针对 Github Action 制作的，适用于 GXDE 的内核工具工程
sudo sed -i "/deb-src/s/# //g" /etc/apt/sources.list
echo "deb-src https://deb.debian.org/debian/ bookworm main contrib non-free non-free-firmware" | sudo tee /etc/apt/sources.list.d/debian-bookworm-source.list
cd $(dirname $0)
rm -rfv build
mkdir build
cd build
# 安装依赖
sudo apt update
sudo apt install -y aria2
sudo apt build-dep -y linux
sudo apt install gcc-riscv64-linux-gnu gcc-mips-linux-gnu gcc-aarch64-linux-gnu gcc-mips64el-linux-gnuabi64 -y
sudo apt install gcc-loongarch64-linux-gnu -y
sudo apt install -y libssl-dev wget xz-utils make gcc flex bison dpkg-dev bc rsync kmod cpio libssl-dev git vim libelf-dev zstd
sudo apt install -y wget xz-utils make gcc flex bison dpkg-dev bc rsync kmod cpio libssl-dev git lsb vim libelf-dev
# 解压源码包
aria2c $kernelUrl
tar -xf $(basename $kernelUrl)
mv */* . -v
# 拷贝配置文件
case $1 in
    "i386")
        cp -v ../config-i386-gxde .config
    ;;
    "amd64")
        cp -v ../config-amd64-gxde .config
    ;;
    "arm64")
        cp -v ../config-6.12.5-gxde-hwe-hisilicon .config
    ;;
    "loong64" )
        cp -v ../config-loong64-4k-pagesize .config
    ;;
    "riscv64" )
        cp -v ../config-riscv64-gxde .config
    ;;
    "mips64el" )
        cp -v ../config-mips64el-gxde .config
    ;;
    *)
        cp -v ../config-amd64-gxde .config
    ;;
esac

# 合并补丁
git apply ../patch/*

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
sudo apt install libssl-dev -y
case $1 in
    "i386")
        sudo env DEBEMAIL="gfdgd xi <3025613752@qq.com>" make bindeb-pkg -j"$CPU_CORES"
    ;;
    "amd64")
        sudo env DEBEMAIL="gfdgd xi <3025613752@qq.com>" make bindeb-pkg -j"$CPU_CORES"
    ;;
    "arm64")
        sudo env DEBEMAIL="gfdgd xi <3025613752@qq.com>" make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu-  bindeb-pkg -j"$CPU_CORES"
    ;;
    "loong64")
        sudo env DEBEMAIL="gfdgd xi <3025613752@qq.com>" make ARCH=loongarch CROSS_COMPILE=loongarch64-linux-gnu- bindeb-pkg -j"$CPU_CORES"
    ;;
    "riscv64" )
        sudo env DEBEMAIL="gfdgd xi <3025613752@qq.com>" make ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- bindeb-pkg -j"$CPU_CORES"
    ;;
    "mips64el" )
        sudo env DEBEMAIL="gfdgd xi <3025613752@qq.com>" make ARCH=mips CROSS_COMPILE=mips64el-linux-gnuabi64- bindeb-pkg -j"$CPU_CORES"
    ;;
    *)
        sudo env DEBEMAIL="gfdgd xi <3025613752@qq.com>" make ARCH=$1 CROSS_COMPILE=$1-linux-gnu- bindeb-pkg -j"$CPU_CORES"
    ;;
esac

sudo mv ../*.deb ../.. -v
