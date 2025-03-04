#!/bin/bash

if ! which ndk-build >/dev/null 2>&1;then
    export ANDROID_NDK=/root/android-ndk-r23b
    export PATH=$PATH:$ANDROID_NDK
    if [ ! -d NDK ];then
        mkdir -p NDK
        (
            cd NDK
            wget https://dl.google.com/android/repository/android-ndk-r24-linux-x86_64.zip
            unzip android-ndk-r22b-linux-x86_64.zip
        )

    fi
fi
# Ensure busybox exists first
if [ ! -f busybox/build/busybox ];then
    (
        cd busybox
        bash build.sh
    )
fi

# Run NDK build first
pushd native
ndk-build -j || exit 1
popd

rm -Rf rootfs rootfs.img

# This list should include all possible first-stage mountpoints on all known devices
mkdir -p rootfs/{apex,sbin,bin,config,proc,sys,dev,system/bin,vendor,product,odm,mnt,first_stage_ramdisk,tmp,metadata,bt_firmware,efs,firmware,oem,persist,postinstall,system_ext,sec_storage,dev/pts,dev/socket,sys/fs/selinux,mnt/vendor,mnt/product,debug_ramdisk,system/system_ext/etc/init/config,system/etc/init/config/,ramdisk,oldroot}
# Temporary directories for Paralloid's boot process
mkdir -p rootfs/target/ rootfs/target_tmp/

cp busybox/build/busybox rootfs/bin/busybox
chmod 0755 rootfs/bin/busybox

echo /oem > rootfs/system/system_ext/etc/init/config/skip_mount.cfg
echo /product >> rootfs/system/system_ext/etc/init/config/skip_mount.cfg
echo /system_ext >> rootfs/system/system_ext/etc/init/config/skip_mount.cfg

echo /oem > rootfs/system/etc/init/config/skip_mount.cfg
echo /product >> rootfs/system/etc/init/config/skip_mount.cfg
echo /system_ext >> rootfs/system/etc/init/config/skip_mount.cfg

for i in acpid add-shell addgroup adduser adjtimex arch arp arping ash awk base64 basename bc beep        blkdiscard blkid blockdev bootchartd brctl bunzip2 bzcat bzip2 cal cat chat chattr chgrp chmod        chown chpasswd chpst chroot chrt chvt cksum clear cmp comm conspy cp cpio crond crontab cryptpw        cttyhack cut date dc dd deallocvt delgroup deluser depmod devmem df dhcprelay diff dirname dmesg        dnsd dnsdomainname dos2unix dpkg dpkg-deb du dumpkmap dumpleases echo ed egrep eject env envdir        envuidgid ether-wake expand expr factor fakeidentd fallocate false fatattr fbset fbsplash fdflush        fdformat fdisk fgconsole fgrep find findfs flock fold free freeramdisk fsck fsck.minix fsfreeze        fstrim fsync ftpd ftpget ftpput fuser getopt getty grep groups gunzip gzip halt hd hdparm head        hexdump hexedit hostid hostname httpd hush hwclock i2cdetect i2cdump i2cget i2cset i2ctransfer id        ifconfig ifdown ifenslave ifplugd ifup inetd init insmod install ionice iostat ip ipaddr ipcalc        ipcrm ipcs iplink ipneigh iproute iprule iptunnel kbd_mode kill killall killall5 klogd last less        link linux32 linux64 linuxrc ln loadfont loadkmap logger login logname logread losetup lpd lpq        lpr ls lsattr lsmod lsof lspci lsscsi lsusb lzcat lzma lzop makedevs makemime man md5sum mdev        mesg microcom mkdir mkdosfs mkfifo mkfs.ext2 mkfs.minix mkfs.vfat mknod mkpasswd mkswap        mktemp modinfo modprobe more mount mountpoint mpstat mt mv nameif nanddump nandwrite nbd-client        nc netstat nice nl nmeter nohup nologin nproc nsenter nslookup ntpd nuke od openvt partprobe        passwd paste patch pgrep pidof ping ping6 pipe_progress pivot_root pkill pmap popmaildir poweroff        powertop printenv printf ps pscan pstree pwd pwdx raidautorun rdate rdev readahead readlink        readprofile realpath reboot reformime remove-shell renice reset resize resume rev rm rmdir rmmod        route rpm rpm2cpio rtcwake run-init run-parts runlevel runsv runsvdir rx script scriptreplay sed        sendmail seq setarch setconsole setfattr setfont setkeycodes setlogcons setpriv setserial setsid        setuidgid sh sha1sum sha256sum sha3sum sha512sum showkey shred shuf slattach sleep smemcap        softlimit sort split ssl_client start-stop-daemon stat strings stty su sulogin sum sv svc svlogd        svok swapoff swapon switch_root sync sysctl syslogd tac tail tar taskset tc tcpsvd tee telnet        telnetd test tftp tftpd time timeout top touch tr traceroute traceroute6 true truncate ts tty        ttysize tunctl ubiattach ubidetach ubimkvol ubirename ubirmvol ubirsvol ubiupdatevol udhcpc udhcpc6        udhcpd udpsvd uevent umount uname unexpand uniq unix2dos unlink unlzma unshare unxz unzip uptime        users usleep uudecode uuencode vconfig vi vlock volname w wall watch watchdog wc wget which who        whoami whois xargs xxd xz xzcat yes zcat zcip;do
    ln -s /bin/busybox rootfs/bin/$i
done
ln -s /bin/busybox rootfs/sbin/mount
ln -s /bin/busybox rootfs/sbin/dd
ln -s /bin/busybox rootfs/sbin/umount
ln -s /bin/busybox rootfs/sbin/dmesg
ln -s /bin/busybox rootfs/sbin/ifconfig
ln -s /bin/busybox rootfs/sbin/route
ln -s /bin/busybox rootfs/sbin/mdev
ln -s /bin/busybox rootfs/sbin/telnetd

cp files/adb_debug.prop rootfs/adb_debug.prop
chmod 0644 rootfs/adb_debug.prop

cp files/init rootfs/system/bin/init
cp files/mkfs.f2fs rootfs/bin/mkfs.f2fs
chmod 0755 rootfs/system/bin/init
chmod 0755 rootfs/bin/mkfs.f2fs

cd rootfs
ln -s system/bin/init init
cd ..

cp files/format-userdata-image rootfs/bin/format-userdata-image
cp files/format-userdata-image-fbe rootfs/bin/format-userdata-image-fbe
cp files/recursive_umount rootfs/bin/recursive_umount
chmod 0755 rootfs/bin/format-userdata-image
chmod 0755 rootfs/bin/format-userdata-image-fbe
chmod 0755 rootfs/bin/recursive_umount

cp native/libs/arm64-v8a/e2fsdroid rootfs/bin/e2fsdroid
chmod 0755 rootfs/bin/e2fsdroid
cp native/libs/arm64-v8a/mke2fs rootfs/bin/mke2fs
chmod 0755 rootfs/bin/mke2fs

cp native/libs/arm64-v8a/paralloid_ui rootfs/bin/paralloid_ui
cp native/libs/arm64-v8a/minfastbootd rootfs/bin/minfastbootd
cp native/libs/arm64-v8a/move_mount_tree rootfs/bin/move_mount_tree
chmod 0755 rootfs/bin/paralloid_ui
chmod 0755 rootfs/bin/minfastbootd
chmod 0755 rootfs/bin/move_mount_tree

mkdir -p rootfs/res/images
cp files/fonts/12x22.png rootfs/res/images/font.png
cp files/fonts/18x32.png rootfs/res/images/font_18x32.png

mkfs.ext4 -d rootfs -b 4096 rootfs.img 64m
