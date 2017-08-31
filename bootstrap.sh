#!/usr/bin/env bash

apt-get update -qq > /dev/null
apt-get dist-upgrade -y
apt-get install -y tmux net-tools vim htop

# /data stuff (assuming we have an /dev/sdb)
apt-get install -y xfsprogs parted lvm2

parted /dev/sdb mklabel msdos
parted /dev/sdb mkpart primary 512 100%
pvcreate /dev/sdb1
vgcreate data /dev/sdb1
lvcreate -l100%FREE -n data data
mkfs.xfs /dev/data/data
mkdir /data
echo `blkid /dev/data/data | awk '{print $2}' | sed 's/"//g'` /data xfs noatime,nobarrier 0 0 >> /etc/fstab
mount /dev/data/data /data
