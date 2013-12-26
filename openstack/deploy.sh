#!/bin/bash

ALL_COMMANDS=('install' 'config' 'start' 'stop' 'restart' 'remove' 'reinstall')
ALL_SERVICES=('mysql' 'rabbitmq' 'keystone' 'glance' 'cinder' 'nova')

usage() {
    echo "usage: $0 <command> <service>"
    echo "<command>: [${ALL_COMMANDS[@]/%/,}]"
    echo "<service>: [${ALL_SERVICES[@]/%/,}]"
    exit
}

is_valid_command() {
    local command=$1
    for val in ${ALL_COMMANDS[@]}; do
        if [[ "${val}" == "${command}" ]]; then
            return 0
        fi
    done
    return 1
}

is_valid_service() {
    local service=$1
    for val in ${ALL_SERVICES[@]}; do
        if [[ "${val}" == "${service}" ]]; then
            return 0
        fi
    done
    return 1
}

## check parameters
if [[ $# -ne 2 ]]; then
    usage
fi

command=$1
service=$2

is_valid_command ${command} || usage
is_valid_service ${service} || usage

## source functions
topdir=$(cd $(dirname $0) && pwd)
if [[ -f "${topdir}/fermentrc" ]]; then
    source ${topdir}/fermentrc
fi
source ${topdir}/lib/common
source ${topdir}/lib/${service}

## check necessary parameters
if [[ -z "${SERVICE_HOST}" || -z "${HOST_ADDRESS}" ]]; then
    echo "environment variable 'SERVICE_HOST' and 'HOST_ADDRESS' can not be null"
    echo "set those two environment variable and run this scirpt again."
    exit
fi

## execute functions
if [[ "install" == "${command}" ]]; then
    eval "install_${service}"
    eval "configure_${service}"
    eval "init_${service}"
elif [[ "config" == "${command}" ]]; then
    eval "configure_${service}"
elif [[ "start" == "${command}" ]]; then
    eval "start_${service}"
elif [[ "stop" == "${command}" ]]; then
    eval "stop_${service}"
elif [[ "restart" == "${command}" ]]; then
    eval "stop_${service}"
    eval "start_${service}"
elif [[ "remove" == "${command}" ]]; then
    eval "stop_${service}"
    eval "cleanup_${service}"
elif [[ "reinstall" == "${command}" ]]; then
    eval "stop_${service}"
    eval "cleanup_${service}"
    eval "install_${service}"
    eval "configure_${service}"
    eval "init_${service}"
else
    usage
fi
