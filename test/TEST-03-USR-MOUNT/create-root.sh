#!/bin/sh
# don't let udev and this script step on eachother's toes
for x in 64-lvm.rules 70-mdadm.rules 99-mount-rules; do
    > "/etc/udev/rules.d/$x"
done
rm -f -- /etc/lvm/lvm.conf
udevadm control --reload
set -e
# save a partition at the beginning for future flagging purposes
sfdisk -C 5120 -H 2 -S 32 -L /dev/sda <<EOF
,16
,
EOF

sfdisk -C 5120 -H 2 -S 32 -L /dev/sdb <<EOF
,16
,
EOF

modprobe btrfs
mkfs.btrfs -L dracut /dev/sda2
mkfs.btrfs -L dracutusr /dev/sdb2
btrfs device scan /dev/sda2
btrfs device scan /dev/sdb2
mkdir -p /root
mount -t btrfs /dev/sda2 /root
[ -d /root/usr ] || mkdir /root/usr
mount -t btrfs /dev/sdb2 /root/usr
btrfs subvolume create /root/usr/usr
umount /root/usr
mount -t btrfs -o subvol=usr /dev/sdb2 /root/usr
cp -a -t /root /source/*
mkdir -p /root/run
umount /root/usr
umount /root
echo "dracut-root-block-created" >/dev/sda1
sync
poweroff -f

