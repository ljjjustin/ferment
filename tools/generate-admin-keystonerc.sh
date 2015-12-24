#!/bin/bash

curdir=$(cd $(dirname $0) && pwd)
topdir=$(dirname ${curdir})

source ${topdir}/fermentrc
source ${topdir}/services/common

ADMIN_TENANT_NAME=${ADMIN_TENANT_NAME:-admin}
ADMIN_USERNAME=${ADMIN_USERNAME:-admin}
ADMIN_PASSWORD=${ADMIN_PASSWORD:-novanova}

cat > ~/adminrc << EOF
export OS_PROJECT_DOMAIN_ID=default
export OS_USER_DOMAIN_ID=default
export OS_PROJECT_NAME=${ADMIN_TENANT_NAME}
export OS_TENANT_NAME=${ADMIN_TENANT_NAME}
export OS_USERNAME=${ADMIN_USERNAME}
export OS_PASSWORD=${ADMIN_PASSWORD}
export OS_AUTH_URL=http://${SERVICE_HOST}:35357/v3
export OS_IDENTITY_API_VERSION=3
EOF

ensure_keystone_accounts "${ADMIN_TENANT_NAME}" "${ADMIN_USERNAME}" "${ADMIN_PASSWORD}" admin
