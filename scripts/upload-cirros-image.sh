#!/bin/bash

topdir=$(cd $(dirname $0) && pwd)
cirros_image=${topdir}/cirros-image-x64.img
IMAGE_NAME="cirros-image-x64"

if [ ! -f "${cirros_image}" ]; then
    wget -O ${cirros_image} http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img
fi

glance image-create --name "${IMAGE_NAME}" --visibility public --container-format bare --disk-format raw --file "${cirros_image}" --progress
