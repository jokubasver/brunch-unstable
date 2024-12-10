#!/bin/bash

set -x
NTHREADS=$(nproc)

rm -rf ./kernels
mkdir ./kernels

rm -rf ./kernel
mkdir ./kernel


cwd="$(pwd)"
chromeos_version="R126"

apply_patches()
{
for patch_type in "base" "others" "chromeos" "all_devices" "surface_devices" "surface_go_devices" "surface_mwifiex_pcie_devices" "surface_np3_devices" "macbook" "fyde" ; do
	if [ -d "./kernel-patches/$1/$patch_type" ]; then
		for patch in ./kernel-patches/"$1/$patch_type"/*.patch; do
			echo "Applying patch: $patch"
			patch -d"./kernels/$1" -p1 --no-backup-if-mismatch -N < "$patch" || { echo "Kernel $1 patch failed"; exit 1; }
		done
	fi
done

echo "$1" | grep -qi "surface"
if [ "$?" -eq 0 ]; then
	for patch in ./kernel-patches/"$1"/surface/*.patch; do
		echo "Applying patch: $patch"
		patch -d"./kernels/$1" -p1 --no-backup-if-mismatch -N < "$patch" || { echo "Kernel $1 patch failed"; exit 1; }
	done
fi
}

make_config()
{
sed -i -z 's@# Detect buggy gcc and clang, fixed in gcc-11 clang-14.\n\tdef_bool@# Detect buggy gcc and clang, fixed in gcc-11 clang-14.\n\tdef_bool $(success,echo 0)\n\t#def_bool@g' ./kernels/$1/init/Kconfig
if [ "x$1" == "xchromebook-4.19" ]; then config_subfolder=""; else config_subfolder="/chromeos"; fi

make mrproper

case "$1" in
	6.6|6.1|5.15|5.10|5.4|4.19)
		make -C "./kernels/$1" O=out allmodconfig || { echo "Kernel $1 configuration failed"; exit 1; }
		sed '/CONFIG_ACPI\|CONFIG_AMD\|CONFIG_ATH\|CONFIG_AXP\|CONFIG_B4\|CONFIG_BACKLIGHT\|CONFIG_BATTERY\|CONFIG_BCM\|CONFIG_BN\|CONFIG_BRCM\|CONFIG_BRIDGE\|CONFIG_BT\|CONFIG_CEC\|CONFIG_CFG\|CONFIG_CHARGER\|CONFIG_CRYPTO\|CONFIG_DRM_AMD\|CONFIG_DRM_GMA\|CONFIG_DRM_NOUVEAU\|CONFIG_DRM_RADEON\|CONFIG_DW_DMAC\|CONFIG_EXTCON\|CONFIG_FIREWIRE\|CONFIG_FRAMEBUFFER_CONSOLE\|CONFIG_GENERIC\|CONFIG_GPIO\|CONFIG_HID\|CONFIG_HOSTAP\|CONFIG_I2C\|CONFIG_I4\|CONFIG_IC\|CONFIG_IG\|CONFIG_INET\|CONFIG_INPUT\|CONFIG_INTEL\|CONFIG_IP\|CONFIG_IWL\|CONFIG_IX\|CONFIG_JOYSTICK\|CONFIG_KEYBOARD\|CONFIG_LEDS\|CONFIG_LIB\|CONFIG_MAC\|CONFIG_MANAGER\|CONFIG_MEDIA_CONTROLLER\|CONFIG_MFD\|CONFIG_ML\|CONFIG_MMC\|CONFIG_MOUSE\|CONFIG_MT7\|CONFIG_MW\|CONFIG_NET\|CONFIG_NFC\|CONFIG_NL\|CONFIG_NVME\|CONFIG_PATA\|CONFIG_POWER\|CONFIG_PWM\|CONFIG_REGULATOR\|CONFIG_RMI\|CONFIG_RT\|CONFIG_SATA\|CONFIG_SCSI\|CONFIG_SENSORS\|CONFIG_SND\|CONFIG_SPI\|CONFIG_SQUASHFS\|CONFIG_SSB\|CONFIG_TABLET\|CONFIG_TCP\|CONFIG_THUNDERBOLT\|CONFIG_TOUCHSCREEN\|CONFIG_TPS68470\|CONFIG_TYPEC\|CONFIG_USB\|CONFIG_VHOST\|CONFIG_VIDEO\|CONFIG_W1\|CONFIG_WL\|CONFIG_XDP\|CONFIG_XFRM/!d' "./kernels/$1/out/.config" >> "./kernels/$1/arch/x86/configs/chromeos_defconfig" || { echo "Kernel $1 configuration failed"; exit 1; }
		make -C "./kernels/$1" O=out allyesconfig || { echo "Kernel $1 configuration failed"; exit 1; }
		sed '/CONFIG_ATA\|CONFIG_CROS\|CONFIG_HOTPLUG\|CONFIG_MDIO\|CONFIG_PERF\|CONFIG_PINCTRL\|CONFIG.*_PMIC\|CONFIG_SATA\|CONFIG_SERI\|CONFIG_USB_STORAGE\|CONFIG_USB_XHCI\|CONFIG_USB_OHCI\|CONFIG_USB_EHCI\|CONFIG_VIRTIO/!d' "./kernels/$1/out/.config" >> "./kernels/$1/arch/x86/configs/chromeos_defconfig" || { echo "Kernel $1 configuration failed"; exit 1; }
		sed -i '/_DBG\|_DEBUG\|_MOCKUP\|_NOCODEC\|_ONLY\|_WARNINGS\|TEST\|USB_OTG\|_PLTFM\|_PLATFORM/d' "./kernels/$1/arch/x86/configs/chromeos_defconfig" || { echo "Kernel $1 configuration failed"; exit 1; }
		sed '/CONFIG_ATH\|CONFIG_DEBUG_INFO\|CONFIG_IWL\|CONFIG_MODULE_COMPRESS\|CONFIG_MOUSE/d' "./kernels/$1/chromeos/config$config_subfolder/base.config" >> "./kernels/$1/arch/x86/configs/chromeos_defconfig" || { echo "Kernel $1 configuration failed"; exit 1; }
		sed '/CONFIG_ATH\|CONFIG_DEBUG_INFO\|CONFIG_IWL\|CONFIG_MODULE_COMPRESS\|CONFIG_MOUSE/d' "./kernels/$1/chromeos/config$config_subfolder/x86_64/common.config" >> "./kernels/$1/arch/x86/configs/chromeos_defconfig" || { echo "Kernel $1 configuration failed"; exit 1; }
		cat "./kernel-patches/brunch_configs"  >> "./kernels/$1/arch/x86/configs/chromeos_defconfig" || { echo "Kernel $1 configuration failed"; exit 1; }
		make -C "./kernels/$1" O=out chromeos_defconfig || { echo "Kernel $1 configuration failed"; exit 1; }
		cp "./kernels/$1/out/.config" "./kernels/$1/arch/x86/configs/chromeos_defconfig" || { echo "Kernel $1 configuration failed"; exit 1; }
	;;
	chromebook*)
		#sed '/CONFIG_DEBUG_INFO\|CONFIG_MODULE_COMPRESS/d' "./kernels/$1/chromeos/config$config_subfolder/base.config" >> "./kernels/$1/arch/x86/configs/chromeos_defconfig" || { echo "Kernel $1 configuration failed"; exit 1; }
		#sed '/CONFIG_DEBUG_INFO\|CONFIG_MODULE_COMPRESS/d' "./kernels/$1/chromeos/config$config_subfolder/x86_64/common.config" >> "./kernels/$1/arch/x86/configs/chromeos_defconfig" || { echo "Kernel $1 configuration failed"; exit 1; }
		#sed '/CONFIG_DEBUG_INFO\|CONFIG_MODULE_COMPRESS/d' "./kernels/$1/chromeos/config$config_subfolder/x86_64/chromeos-intel-pineview.flavour.config" >> "./kernels/$1/arch/x86/configs/chromeos_defconfig" || { echo "Kernel $1 configuration failed"; exit 1; }
		#cat "./kernel-patches/fyde_config"  >> "./kernels/$1/arch/x86/configs/chromeos_defconfig" || { echo "Kernel $1 configuration failed"; exit 1; }
		#make -C "./kernels/$1" O=out chromeos_defconfig || { echo "Kernel $1 configuration failed"; exit 1; }
		#cp "./kernels/$1/out/.config" "./kernels/$1/arch/x86/configs/chromeos_defconfig" || { echo "Kernel $1 configuration failed"; exit 1; }
		#
		make -C "./kernels/$1" O=out allmodconfig || { echo "Kernel $1 configuration failed"; exit 1; }
		sed '/CONFIG_ACPI\|CONFIG_AMD\|CONFIG_ATH\|CONFIG_AXP\|CONFIG_B4\|CONFIG_BACKLIGHT\|CONFIG_BATTERY\|CONFIG_BCM\|CONFIG_BN\|CONFIG_BRCM\|CONFIG_BRIDGE\|CONFIG_BT\|CONFIG_CEC\|CONFIG_CFG\|CONFIG_CHARGER\|CONFIG_CRYPTO\|CONFIG_DRM_AMD\|CONFIG_DRM_GMA\|CONFIG_DRM_NOUVEAU\|CONFIG_DRM_RADEON\|CONFIG_DW_DMAC\|CONFIG_EXTCON\|CONFIG_FIREWIRE\|CONFIG_FRAMEBUFFER_CONSOLE\|CONFIG_GENERIC\|CONFIG_GPIO\|CONFIG_HID\|CONFIG_HOSTAP\|CONFIG_I2C\|CONFIG_I4\|CONFIG_IC\|CONFIG_IG\|CONFIG_INET\|CONFIG_INPUT\|CONFIG_INTEL\|CONFIG_IP\|CONFIG_IWL\|CONFIG_IX\|CONFIG_JOYSTICK\|CONFIG_KEYBOARD\|CONFIG_LEDS\|CONFIG_LIB\|CONFIG_MAC\|CONFIG_MANAGER\|CONFIG_MEDIA_CONTROLLER\|CONFIG_MFD\|CONFIG_ML\|CONFIG_MMC\|CONFIG_MOUSE\|CONFIG_MT7\|CONFIG_MW\|CONFIG_NET\|CONFIG_NFC\|CONFIG_NL\|CONFIG_NVME\|CONFIG_PATA\|CONFIG_POWER\|CONFIG_PWM\|CONFIG_REGULATOR\|CONFIG_RMI\|CONFIG_RT\|CONFIG_SATA\|CONFIG_SCSI\|CONFIG_SENSORS\|CONFIG_SND\|CONFIG_SPI\|CONFIG_SQUASHFS\|CONFIG_SSB\|CONFIG_TABLET\|CONFIG_TCP\|CONFIG_THUNDERBOLT\|CONFIG_TOUCHSCREEN\|CONFIG_TPS68470\|CONFIG_TYPEC\|CONFIG_USB\|CONFIG_VHOST\|CONFIG_VIDEO\|CONFIG_W1\|CONFIG_WL\|CONFIG_XDP\|CONFIG_XFRM/!d' "./kernels/$1/out/.config" >> "./kernels/$1/arch/x86/configs/chromeos_defconfig" || { echo "Kernel $1 configuration failed"; exit 1; }
		make -C "./kernels/$1" O=out allyesconfig || { echo "Kernel $1 configuration failed"; exit 1; }
		sed '/CONFIG_ATA\|CONFIG_CROS\|CONFIG_HOTPLUG\|CONFIG_MDIO\|CONFIG_PERF\|CONFIG_PINCTRL\|CONFIG.*_PMIC\|CONFIG_SATA\|CONFIG_SERI\|CONFIG_USB_STORAGE\|CONFIG_USB_XHCI\|CONFIG_USB_OHCI\|CONFIG_USB_EHCI\|CONFIG_VIRTIO/!d' "./kernels/$1/out/.config" >> "./kernels/$1/arch/x86/configs/chromeos_defconfig" || { echo "Kernel $1 configuration failed"; exit 1; }
		sed -i '/_DBG\|_DEBUG\|_MOCKUP\|_NOCODEC\|_ONLY\|_WARNINGS\|TEST\|USB_OTG\|_PLTFM\|_PLATFORM/d' "./kernels/$1/arch/x86/configs/chromeos_defconfig" || { echo "Kernel $1 configuration failed"; exit 1; }
		sed '/CONFIG_ATH\|CONFIG_DEBUG_INFO\|CONFIG_IWL\|CONFIG_MODULE_COMPRESS\|CONFIG_MOUSE/d' "./kernels/$1/chromeos/config$config_subfolder/base.config" >> "./kernels/$1/arch/x86/configs/chromeos_defconfig" || { echo "Kernel $1 configuration failed"; exit 1; }
		sed '/CONFIG_ATH\|CONFIG_DEBUG_INFO\|CONFIG_IWL\|CONFIG_MODULE_COMPRESS\|CONFIG_MOUSE/d' "./kernels/$1/chromeos/config$config_subfolder/x86_64/common.config" >> "./kernels/$1/arch/x86/configs/chromeos_defconfig" || { echo "Kernel $1 configuration failed"; exit 1; }
		cat "./kernel-patches/brunch_configs"  >> "./kernels/$1/arch/x86/configs/chromeos_defconfig" || { echo "Kernel $1 configuration failed"; exit 1; }
		make -C "./kernels/$1" O=out chromeos_defconfig || { echo "Kernel $1 configuration failed"; exit 1; }
		cp "./kernels/$1/out/.config" "./kernels/$1/arch/x86/configs/chromeos_defconfig" || { echo "Kernel $1 configuration failed"; exit 1; }
		echo 'CONFIG_LOCALVERSION="-chromebook"' >> out/.config
	;;
	surface*)
		sed '/CONFIG_DEBUG_INFO\|CONFIG_MODULE_COMPRESS/d' "./kernels/$1/chromeos/config$config_subfolder/base.config" >> "./kernels/$1/arch/x86/configs/chromeos_defconfig" || { echo "Kernel $1 configuration failed"; exit 1; }
		sed '/CONFIG_DEBUG_INFO\|CONFIG_MODULE_COMPRESS/d' "./kernels/$1/chromeos/config$config_subfolder/x86_64/common.config" >> "./kernels/$1/arch/x86/configs/chromeos_defconfig" || { echo "Kernel $1 configuration failed"; exit 1; }
		sed '/CONFIG_DEBUG_INFO\|CONFIG_MODULE_COMPRESS/d' "./kernels/$1/chromeos/config$config_subfolder/x86_64/chromeos-intel-pineview.flavour.config" >> "./kernels/$1/arch/x86/configs/chromeos_defconfig" || { echo "Kernel $1 configuration failed"; exit 1; }
		cat "./kernel-patches/fyde_config"  >> "./kernels/$1/arch/x86/configs/chromeos_defconfig" || { echo "Kernel $1 configuration failed"; exit 1; }
		cat "./kernel-patches/surface_config"  >> "./kernels/$1/arch/x86/configs/chromeos_defconfig" || { echo "Kernel $1 configuration failed"; exit 1; }
		make -C "./kernels/$1" O=out chromeos_defconfig || { echo "Kernel $1 configuration failed"; exit 1; }
		cp "./kernels/$1/out/.config" "./kernels/$1/arch/x86/configs/chromeos_defconfig" || { echo "Kernel $1 configuration failed"; exit 1; }
		echo 'CONFIG_LOCALVERSION="-surface"' >> "./kernels/$1/out/.config"
	;;
	*)
		echo 'CONFIG_LOCALVERSION="-fyde-brunch-damenly"' > "./kernels/$1/arch/x86/configs/chromeos_defconfig" || { echo "Kernel $1 configuration failed"; exit 1; }
		sed '/CONFIG_DEBUG_INFO\|CONFIG_MODULE_COMPRESS/d' "./kernels/$1/chromeos/config$config_subfolder/base.config" >> "./kernels/$1/arch/x86/configs/chromeos_defconfig" || { echo "Kernel $1 configuration failed"; exit 1; }
		sed '/CONFIG_DEBUG_INFO\|CONFIG_MODULE_COMPRESS/d' "./kernels/$1/chromeos/config$config_subfolder/x86_64/common.config" >> "./kernels/$1/arch/x86/configs/chromeos_defconfig" || { echo "Kernel $1 configuration failed"; exit 1; }
		sed '/CONFIG_DEBUG_INFO\|CONFIG_MODULE_COMPRESS/d' "./kernels/$1/chromeos/config$config_subfolder/x86_64/chromeos-intel-pineview.flavour.config" >> "./kernels/$1/arch/x86/configs/chromeos_defconfig" || { echo "Kernel $1 configuration failed"; exit 1; }
		cat "./kernel-patches/fyde_config"  >> "./kernels/$1/arch/x86/configs/chromeos_defconfig" || { echo "Kernel $1 configuration failed"; exit 1; }
		make -C "./kernels/$1" O=out chromeos_defconfig || { echo "Kernel $1 configuration failed"; exit 1; }
		cp "./kernels/$1/out/.config" "./kernels/$1/arch/x86/configs/chromeos_defconfig" || { echo "Kernel $1 configuration failed"; exit 1; }
	;;
esac
}

download_and_build_kernels()
{
# Find the ChromiumOS kernel remote path corresponding to the release
kernel_remote_path="$(git ls-remote https://chromium.googlesource.com/chromiumos/third_party/kernel/ | grep "refs/heads/release-$chromeos_version" | head -1 | sed -e 's#.*\t##' -e 's#chromeos-.*##' | sort -u)chromeos-"
[ ! "x$kernel_remote_path" == "x" ] || { echo "Remote path not found"; exit 1; }
echo "kernel_remote_path=$kernel_remote_path"

for config in $configs; do
for kernel in $kernels; do
	kernel_version=$(curl -Ls "https://chromium.googlesource.com/chromiumos/third_party/kernel/+/$kernel_remote_path$kernel/Makefile?format=TEXT" | base64 --decode | sed -n -e 1,4p | sed -e '/^#/d' | cut -d'=' -f 2 | sed -z 's#\n##g' | sed 's#^ *##g' | sed 's# #.#g')
	echo "kernel_version=$kernel_version"
	local kdir="${config}-${kernel}"
	[ ! "x$kernel_version" == "x" ] || { echo "Kernel version not found"; exit 1; }
	case "$kernel" in
		6.6)
			echo "Downloading ChromiumOS kernel source for kernel $kernel version $kernel_version"
			[ ! -f "./kernels/chromiumos-$kernel.tar.gz" ] && curl -L "https://chromium.googlesource.com/chromiumos/third_party/kernel/+archive/$kernel_remote_path$kernel.tar.gz" -o "./kernels/chromiumos-$kernel.tar.gz" || { echo "Kernel source download failed"; exit 1; }
			mkdir "./kernels/$kdir"
			tar -C "./kernels/$kdir" -zxf "./kernels/chromiumos-$kernel.tar.gz" || { echo "Kernel $kernel source extraction failed"; exit 1; }
			apply_patches "$kdir"
			make_config "$kdir"

			echo "Building kernel $kdir"

			KCONFIG_NOTIMESTAMP=1 KBUILD_BUILD_TIMESTAMP='' KBUILD_BUILD_USER=chronos KBUILD_BUILD_HOST=localhost make -C "./kernels/$kdir" -j"$NTHREADS" O=out || { echo "Kernel build failed"; exit 1; }

			pushd
			kernel=$kdir
			cd "./kernels/$kdir"
			kernel_version="$(file ./out/arch/x86/boot/bzImage | cut -d' ' -f9)"
			mkdir "${cwd}/kernel/$kdir"
			[ ! "$kernel_version" == "" ] || { echo "Failed to read version for kernel $kernel"; exit 1; }
			cp ./out/arch/x86/boot/bzImage ${cwd}/kernel/${kdir}/vmlinux || { echo "Failed to copy the kernel $kernel"; exit 1; }
			make -j"$NTHREADS" O=out INSTALL_MOD_STRIP=1 INSTALL_MOD_PATH=${cwd}/kernel/${kdir} modules_install || { echo "Failed to install modules for kernel $kernel"; exit 1; }
			rm -f ${cwd}/kernel/${kdir}/lib/modules/"$kernel_version"/build
			rm -f ${cwd}/kernel/${kdir}/lib/modules/"$kernel_version"/source
			popd

			#mkdir "./kernels/6.6"
			#tar -C "./kernels/6.6" -zxf "./kernels/chromiumos-$kernel.tar.gz" chromeos || { echo "Kernel $kernel source extraction failed"; exit 1; }
			#echo "Downloading Mainline kernel source for kernel $kernel version $kernel_version"
			#curl -L "https://mirrors.edge.kernel.org/pub/linux/kernel/v6.x/linux-$kernel_version.tar.gz" -o "./kernels/mainline-$kernel.tar.gz" || { echo "Kernel source download failed"; exit 1; }
			#tar -C "./kernels/6.6" -zxf "./kernels/mainline-$kernel.tar.gz" --strip 1 || { echo "Kernel $kernel source extraction failed"; exit 1; }
			#rm -f "./kernels/mainline-$kernel.tar.gz"
			#apply_patches "6.6"
			#make_config "6.6"
		;;
		6.1)
			echo "Downloading ChromiumOS kernel source for kernel $kernel version $kernel_version"
			curl -L "https://chromium.googlesource.com/chromiumos/third_party/kernel/+archive/$kernel_remote_path$kernel.tar.gz" -o "./kernels/chromiumos-$kernel.tar.gz" || { echo "Kernel source download failed"; exit 1; }
			mkdir "./kernels/chromebook-6.1" "./kernels/6.1"
			tar -C "./kernels/chromebook-6.1" -zxf "./kernels/chromiumos-$kernel.tar.gz" || { echo "Kernel $kernel source extraction failed"; exit 1; }
			tar -C "./kernels/6.1" -zxf "./kernels/chromiumos-$kernel.tar.gz" chromeos || { echo "Kernel $kernel source extraction failed"; exit 1; }
			rm -f "./kernels/chromiumos-$kernel.tar.gz"
			apply_patches "chromebook-6.1"
			make_config "chromebook-6.1"
			echo "Downloading Mainline kernel source for kernel $kernel version $kernel_version"
			curl -L "https://mirrors.edge.kernel.org/pub/linux/kernel/v6.x/linux-$kernel_version.tar.gz" -o "./kernels/mainline-$kernel.tar.gz" || { echo "Kernel source download failed"; exit 1; }
			tar -C "./kernels/6.1" -zxf "./kernels/mainline-$kernel.tar.gz" --strip 1 || { echo "Kernel $kernel source extraction failed"; exit 1; }
			rm -f "./kernels/mainline-$kernel.tar.gz"
			apply_patches "6.1"
			make_config "6.1"
		;;
		5.15)
			echo "Downloading ChromiumOS kernel source for kernel $kernel version $kernel_version"
			curl -L "https://chromium.googlesource.com/chromiumos/third_party/kernel/+archive/$kernel_remote_path$kernel.tar.gz" -o "./kernels/chromiumos-$kernel.tar.gz" || { echo "Kernel source download failed"; exit 1; }
			mkdir "./kernels/chromebook-5.15" "./kernels/5.15"
			tar -C "./kernels/chromebook-5.15" -zxf "./kernels/chromiumos-$kernel.tar.gz" || { echo "Kernel $kernel source extraction failed"; exit 1; }
			tar -C "./kernels/5.15" -zxf "./kernels/chromiumos-$kernel.tar.gz" chromeos || { echo "Kernel $kernel source extraction failed"; exit 1; }
			rm -f "./kernels/chromiumos-$kernel.tar.gz"
			apply_patches "chromebook-5.15"
			make_config "chromebook-5.15"
			echo "Downloading Mainline kernel source for kernel $kernel version $kernel_version"
			curl -L "https://mirrors.edge.kernel.org/pub/linux/kernel/v5.x/linux-$kernel_version.tar.gz" -o "./kernels/mainline-$kernel.tar.gz" || { echo "Kernel source download failed"; exit 1; }
			tar -C "./kernels/5.15" -zxf "./kernels/mainline-$kernel.tar.gz" --strip 1 || { echo "Kernel $kernel source extraction failed"; exit 1; }
			rm -f "./kernels/mainline-$kernel.tar.gz"
			apply_patches "5.15"
			make_config "5.15"
		;;
		*)
			echo "Downloading ChromiumOS kernel source for kernel $kernel version $kernel_version"
			curl -L "https://chromium.googlesource.com/chromiumos/third_party/kernel/+archive/$kernel_remote_path$kernel.tar.gz" -o "./kernels/chromiumos-$kernel.tar.gz" || { echo "Kernel source download failed"; exit 1; }
			mkdir "./kernels/chromebook-$kernel"
			tar -C "./kernels/chromebook-$kernel" -zxf "./kernels/chromiumos-$kernel.tar.gz" || { echo "Kernel $kernel source extraction failed"; exit 1; }
			rm -f "./kernels/chromiumos-$kernel.tar.gz"
			apply_patches "chromebook-$kernel"
			make_config "chromebook-$kernel"
		;;
	esac
done
done

}

configs="$1"
[ -z "$configs" ] && { echo "$1 is empty"; exit 1; }

# Download kernels source
kernels="6.6"

download_and_build_kernels

cd $cwd
rm -rf kernels/*

for config in $configs; do
for kernel in $kernels; do
	kdir="${config}-${kernel}"
	tar --owner=0 --group=0 -C kernel/$kdir -zcvf "${cwd}/${kdir}.tar.gz" ./
done
done
