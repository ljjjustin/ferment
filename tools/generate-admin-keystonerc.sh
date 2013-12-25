#!/bin/bash

curdir=$(cd $(dirname $0) && pwd)
topdir=$(dirname ${curdir})

source ${topdir}/openstack/fermentrc
source ${topdir}/openstack/lib/common

ADMIN_TENANT_NAME=${ADMIN_TENANT_NAME:-admin}
ADMIN_USERNAME=${ADMIN_USERNAME:-admin}
ADMIN_PASSWORD=${ADMIN_PASSWORD:-novanova}

cat > ~/keystonerc << EOF
export OS_USE_KEYRING=false
export OS_TENANT_NAME=${ADMIN_TENANT_NAME}
export OS_USERNAME=${ADMIN_USERNAME}
export OS_PASSWORD=${ADMIN_PASSWORD}
export OS_AUTH_URL=http://${SERVICE_HOST}:35357/v2.0
EOF

ensure_keystone_accounts "${ADMIN_TENANT_NAME}" "${ADMIN_USERNAME}" "${ADMIN_PASSWORD}" admin
