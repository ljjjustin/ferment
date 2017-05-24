#!/bin/bash

# Sanitize language settings to avoid commands bailing out
# with "unsupported locale setting" errors.
unset LANG
unset LANGUAGE
LC_ALL=C
export LC_ALL

# Make sure umask is sane
umask 022

## make directories
rootdir=/opt/yum/chroot

if [ ! -d "${rootdir}" ]; then
    mkdir -p "${rootdir}"
fi
if [ ! -d "${rootdir}/var/lib/rpm" ]; then
    mkdir -p "${rootdir}/var/lib/rpm"
    rpm --rebuilddb --root="${rootdir}"
fi

## initiate rpm & yum
yum --installroot="${rootdir}" --releasever=/ install -y centos-release epel-release yum yum-utils rpm-build

## mount proc & dev
if ! mount | grep -q "${rootdir}/dev"; then
    mount --bind /dev  "${rootdir}/dev"
fi
if ! mount | grep -q "${rootdir}/proc"; then
    mount --bind /proc "${rootdir}/proc"
fi

## config network
cp /etc/resolv.conf "${rootdir}/etc/resolv.conf"
