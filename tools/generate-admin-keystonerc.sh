#!/bin/bash

curdir=$(cd $(dirname $0) && pwd)
topdir=$(dirname ${curdir})

source ${topdir}/.fermentrc
source ${topdir}/services/common

ADMIN_TENANT_NAME=${ADMIN_TENANT_NAME:-admin}
ADMIN_USERNAME=${ADMIN_USERNAME:-admin}
ADMIN_PASSWORD=${ADMIN_PASSWORD:-novanova}

cat > ~/adminrc << EOF
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=${ADMIN_TENANT_NAME}
export OS_TENANT_NAME=${ADMIN_TENANT_NAME}
export OS_USERNAME=${ADMIN_USERNAME}
export OS_PASSWORD=${ADMIN_PASSWORD}
export OS_AUTH_URL=http://${SERVICE_HOST}:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_VOLUME_API_VERSION=2
EOF

init_keystone_auth
openstack domain create --enable Default
ensure_keystone_accounts "${ADMIN_TENANT_NAME}" "${ADMIN_USERNAME}" "${ADMIN_PASSWORD}" admin

# test adminrc
for env in $(printenv | grep OS_ | awk -F '=' '{print $1}'); do unset $env; done
source ~/adminrc
openstack token issue
