#!/bin/bash

set -x
# Convert container image into a container disk (requires sudo)
CONTAINER_RUNTIME=${CONTAINER_RUNTIME:-docker}
RUNC_VERSION=1.1.0
RUNC_STATIC_URL=https://github.com/opencontainers/runc/releases/download/v$RUNC_VERSION/runc.amd64
image=$1
disk_img=/tmp/raw.img
temp_mount=/tmp/container_disk
rootfs=$temp_mount/rootfs
runc_size=10000000
sudo umount $temp_mount

set -e
size=$($CONTAINER_RUNTIME inspect --format '{{.Size}}' $image)
overhead=$(( $size*20/100 ))
total_size=$(( $size + $overhead + $runc_size))
qemu-img create -f raw $disk_img $total_size 
mkfs.ext4 $disk_img
mkdir -p $temp_mount

sudo mount -o loop $disk_img $temp_mount
$CONTAINER_RUNTIME export $($CONTAINER_RUNTIME create $image) -o temp.tar 
sudo mkdir -p $rootfs
sudo tar fx temp.tar -C $rootfs
sudo curl -L -o $temp_mount/runc $RUNC_STATIC_URL
sudo chmod +x $temp_mount/runc
sudo $temp_mount/runc spec
sudo umount $temp_mount

qemu-img convert -f raw -O qcow2 $disk_img disk.qcow2
rm $disk_img

cat <<EOF > Dockerfile.cd
FROM scratch 
COPY disk.qcow2 /disk/disk.img
EOF

$CONTAINER_RUNTIME build -t fio-containerdisk -f Dockerfile.cd .
