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

#### POSTGRESQL SHIT ####

# cstore_fdw
# Columnar store for analytics with PostgreSQL
# https://github.com/citusdata/cstore_fdw
# dependencies
apt-get install -y protobuf-c-compiler libprotobuf-c-dev

# install and stop
apt-get install -y postgresql
postgres_ver=`psql --version | awk '{print $3}' | cut -d'.' -f1,2`
systemctl stop postgresql
sleep 5 # apparently it takes a bit to full shutdown, hacky but okay for now

# lol, one fell swoop
usermod -m -d /data/postgresql postgres

# change data_directory in postgresql.conf
sed -i "s~\(data_directory = \)'/var/lib~\1'\/data~" /etc/postgresql/$postgres_ver/main/postgresql.conf

# build cstore_fdw
apt-get install -y git postgresql-server-dev-${postgres_ver} libdpkg-perl
git clone https://github.com/citusdata/cstore_fdw.git
cd cstore_fdw && PATH=/usr/local/pgsql/bin/:$PATH make && PATH=/usr/local/pgsql/bin/:$PATH make install
echo "shared_preload_libraries = 'cstore_fdw'" >> /etc/postgresql/$postgres_ver/main/postgresql.conf

# start
systemctl start postgresql
