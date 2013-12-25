#!/bin/bash

topdir=$(cd $(dirname $0) && pwd)
cirros_image=${topdir}/cirros-image-x64.img
IMAGE_NAME="cirros-image-x64"

if [ ! -f "${cirros_image}" ]; then
    wget -O ${cirros_image} http://download.cirros-cloud.net/0.3.1/cirros-0.3.1-x86_64-disk.img
fi

glance image-create --name "${IMAGE_NAME}" --public --container-format bare --disk-format raw  < "${cirros_image}"
