#!/bin/bash
#=================================================
shopt -s extglob
kernel_v="$(cat include/kernel-5.10 | grep LINUX_KERNEL_HASH-* | cut -f 2 -d - | cut -f 1 -d ' ')"
echo "KERNEL=${kernel_v}" >> $GITHUB_ENV || true
sed -i "s?targets/%S/packages?targets/%S/$kernel_v?" include/feeds.mk

echo "$(date +"%s")" >version.date
sed -i '/$(curdir)\/compile:/c\$(curdir)/compile: package/opkg/host/compile' package/Makefile
sed -i "s/DEFAULT_PACKAGES:=/DEFAULT_PACKAGES:=luci-app-firewall luci-app-opkg luci-app-upnp luci-app-autoreboot \
luci-base luci-compat luci-lib-ipkg luci-lib-fs \
base-files luci \
coremark wget-ssl curl htop nano kmod-tcp-bbr bash /" include/target.mk
sed -i "s/procd-ujail//" include/target.mk

sed -i '/	refresh_config();/d' scripts/feeds
[ ! -f feeds.conf ] && {
sed -i '$a src-git kiddin9 https://github.com/zhanghaocong/openwrt-packages.git;master' feeds.conf.default
}

./scripts/feeds update -a
./scripts/feeds install -a -p kiddin9 -f
./scripts/feeds install -a
cd feeds/kiddin9; git pull; cd -

mv -f feeds/kiddin9/r81* tmp/

sed -i "s/192.168.1/10.10.1/" package/feeds/kiddin9/base-files/files/bin/config_generate

(
svn export --force https://github.com/coolsnowwolf/lede/trunk/tools/upx tools/upx
svn export --force https://github.com/coolsnowwolf/lede/trunk/tools/ucl tools/ucl
svn co https://github.com/coolsnowwolf/lede/trunk/target/linux/generic/hack-5.10 target/linux/generic/hack-5.10
rm -rf target/linux/generic/hack-5.10/{220-gc_sections*,781-dsa-register*,780-drivers-net*}
) &

sed -i 's/Os/O2/g' include/target.mk
sed -i 's/$(TARGET_DIR)) install/$(TARGET_DIR)) install --force-overwrite --force-maintainer --force-depends/' package/Makefile
sed -i 's/=bbr/=cubic/' package/kernel/linux/files/sysctl-tcp-bbr.conf

# find target/linux/x86 -name "config*" -exec bash -c 'cat kernel.conf >> "{}"' \;
sed -i '$a CONFIG_ACPI=y\nCONFIG_X86_ACPI_CPUFREQ=y\nCONFIG_NR_CPUS=128\nCONFIG_FAT_DEFAULT_IOCHARSET="utf8"\nCONFIG_CRYPTO_CHACHA20_NEON=y\n \
CONFIG_CRYPTO_CHACHA20POLY1305=y\nCONFIG_BINFMT_MISC=y' `find target/linux -path "target/linux/*/config-*"`
sed -i 's/max_requests 3/max_requests 20/g' package/network/services/uhttpd/files/uhttpd.config
#rm -rf ./feeds/packages/lang/{golang,node}
sed -i "s/tty\(0\|1\)::askfirst/tty\1::respawn/g" target/linux/*/base-files/etc/inittab

# (
# if [ -f sdk.tar.xz ]; then
# 	sed -i 's,$(STAGING_DIR_HOST)/bin/upx,upx,' package/feeds/kiddin9/*/Makefile
# 	mkdir sdk
# 	tar -xJf sdk.tar.xz -C sdk
# 	cp -rf sdk/*/staging_dir/* ./staging_dir/
# 	rm -rf sdk.tar.xz sdk
# 	sed -i '/\(tools\|toolchain\)\/Makefile/d' Makefile
# 	if [ -f /usr/bin/python ]; then
# 		ln -sf /usr/bin/python staging_dir/host/bin/python
# 	else
# 		ln -sf /usr/bin/python3 staging_dir/host/bin/python
# 	fi
# 	ln -sf /usr/bin/python3 staging_dir/host/bin/python3
# fi
# ) &
