#!/bin/bash

set -x
# Convert container image into a container disk (requires sudo)
CONTAINER_RUNTIME=${CONTAINER_RUNTIME:-docker}
image=$1
disk_img=/tmp/raw.img
temp_mount=/tmp/container_disk

sudo umount $temp_mount

set -e
size=$($CONTAINER_RUNTIME inspect --format '{{.Size}}' $image)
overhead=$(( $size*20/100 ))
total_size=$(( $size + $overhead ))
qemu-img create -f raw $disk_img $total_size 
mkfs.ext4 $disk_img
mkdir -p $temp_mount

sudo mount -o loop $disk_img $temp_mount
$CONTAINER_RUNTIME export $($CONTAINER_RUNTIME create $image) -o temp.tar 
sudo tar fx temp.tar -C $temp_mount
sudo umount $temp_mount

qemu-img convert -f raw -O qcow2 $disk_img disk.qcow2
rm $disk_img

cat <<EOF > Dockerfile.cd
FROM scratch 
COPY disk.qcow2 /disk/disk.img
EOF

$CONTAINER_RUNTIME build -t fio-containerdisk -f Dockerfile.cd .
