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
sudo apt install -y wget xz-utils make gcc flex bison dpkg-dev bc rsync kmod cpio libssl-dev git vim libelf-dev zstd
# 解压源码包
aria2c $kernelUrl
tar -xf $(basename $kernelUrl)
mv */* . -v
# 拷贝配置文件
cp ../gxde-amd64-config .config
case $1 in
    "amd64")
        cp ../config-amd64-gxde .config
    ;;
    "arm64")
        cp ../config-6.12.5-gxde-hwe-hisilicon .config
    ;;
    "loong64" )
        cp ../config-6.12.9-loong64 .config
    ;;
    "riscv64" )
        cp arch/riscv/configs/nommu_virt_defconfig .config
    ;;
    "mips64el" )
        cp arch/mips/configs/loongson3_defconfig .config
    ;;
    *)
        cp ../config-amd64-gxde .config
    ;;
esac

# 合并补丁
if [[ -d ../patch ]]; then
    git apply ../patch/*
fi

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
case $1 in
    "amd64")
        sudo env DEBEMAIL="gfdgd xi <3025613752@qq.com>" make bindeb-pkg -j"$CPU_CORES"
    ;;
    "arm64")
        sudo env DEBEMAIL="gfdgd xi <3025613752@qq.com>" make bindeb-pkg ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j"$CPU_CORES"
    ;;
    "loongarch")
        sudo env DEBEMAIL="gfdgd xi <3025613752@qq.com>" make bindeb-pkg ARCH=loongarch CROSS_COMPILE=loongarch64-linux-gnu- -j"$CPU_CORES"
    ;;
    "riscv64" )
        sudo env DEBEMAIL="gfdgd xi <3025613752@qq.com>" make bindeb-pkg ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- -j"$CPU_CORES"
    ;;
    "mips64el" )
        sudo env DEBEMAIL="gfdgd xi <3025613752@qq.com>" make bindeb-pkg ARCH=mips CROSS_COMPILE=mips-linux-gnu- -j"$CPU_CORES"
    ;;
    *)
        sudo env DEBEMAIL="gfdgd xi <3025613752@qq.com>" make bindeb-pkg ARCH=$1 CROSS_COMPILE=$1-linux-gnu- -j"$CPU_CORES"
    ;;
esac

sudo mv ../*.deb ../.. -v