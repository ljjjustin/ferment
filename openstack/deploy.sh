#!/bin/bash

usage() {
    echo "usage: $0 <command> <service>"
    echo "<command>: should be one of 'install, config, cleanup'"
    echo "<service>: could be one of 'mysql, rabbitmq, "
    echo "           keystone, glance, cinder, nova"
    exit
}

ALL_COMMANDS=('install' 'config' 'cleanup' 'reinstall')
ALL_SERVICES=('mysql' 'rabbitmq' 'keystone' 'glance' 'cinder' 'nova')

is_valid_command() {
    local command=$1
    for val in ${ALL_COMMANDS[@]}; do
        if [ "${command}" = "${val}" ]; then
            return 0
        fi
    done
    return 1
}

is_valid_service() {
    local service=$1
    for val in ${ALL_SERVICES[@]}; do
        if [ "${service}" = "${val}" ]; then
            return 0
        fi
    done
    return 1
}
## check parameters
if [ $# -ne 2 ]; then
    usage
fi

command=$1
service=$2

is_valid_command ${command} || usage
is_valid_service ${service} || usage

## source functions
topdir=$(cd $(dirname $0) && pwd)
source ${topdir}/lib/common
source ${topdir}/lib/${service}

## execute functions
if [ "${command}" == "install" ]; then
    eval "install_${service}"
    eval "configure_${service}"
    eval "init_${service}"
elif [ "${command}" == "config" ]; then
    eval "configure_${service}"
elif [ "${command}" == "cleanup" ]; then
    eval "stop_${service}"
    eval "cleanup_${service}"
elif [ "${command}" == "reinstall" ]; then
    eval "stop_${service}"
    eval "cleanup_${service}"
    eval "install_${service}"
    eval "configure_${service}"
    eval "init_${service}"
else
    usage
fi
