#!/bin/bash

# Sanitize language settings to avoid commands bailing out
# with "unsupported locale setting" errors.
unset LANG
unset LANGUAGE
LC_ALL=C
export LC_ALL

# Make sure umask is sane
umask 022

## source functions
topdir=$(cd $(dirname $0) && pwd)

## config openstack repo
openstack_reposdir="/opt/openstack"
yum_config_file="${openstack_reposdir}/yum.conf"
repo_config_file="${openstack_reposdir}/openstack.repo"
YUM="yum -c ${yum_config_file}"
YUMDOWNLOADER="yumdownloader -c ${yum_config_file} -y --resolve"

## create yum config
generate_yum_config()
{
    cat > ${yum_config_file} << EOF
[main]
cachedir=/var/cache/yum/\$basearch/\$releasever
keepcache=0
debuglevel=2
exactarch=1
obsoletes=1
plugins=0
gpgcheck=0
timeout=60
installonly_limit=5
reposdir=${openstack_reposdir}
logfile=${openstack_reposdir}/yum.log
EOF
}


## create rpm repository config
generate_repos_config()
{
    cat > ${repo_config_file} << 'EOF'
[base]
name=CentOS-$releasever - Base
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=os&infra=$infra
#baseurl=http://mirror.centos.org/centos/$releasever/os/$basearch/
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

[epel]
name=Extra Packages for Enterprise Linux 7 - $basearch
#baseurl=http://download.fedoraproject.org/pub/epel/7/$basearch
mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=$basearch
failovermethod=priority
enabled=1
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7

[mariadb]
name = MariaDB 10.0
baseurl = http://yum.mariadb.org/10.0/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=0

[openstack-liberty]
name=OpenStack Liberty Repository
baseurl=http://mirror.centos.org/centos/7/cloud/$basearch/openstack-liberty/
enabled=1
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Cloud
EOF
}

## create apache config
generate_apache_config()
{
    cat > /etc/httpd/conf.d/000-repo.conf <<EOF
<VirtualHost *:80>
    ServerAdmin root@localhost
    ServerName  $(hostname)
    DocumentRoot "${openstack_reposdir}"
    <Directory  "${openstack_reposdir}">
        Options +Indexes
        Require all granted
    </Directory>
    ErrorLog logs/repos-error.log
    CustomLog logs/repos-access.log common
</VirtualHost>
EOF
}

## create repostory base dir
if [ ! -d "${openstack_reposdir}" ]
then
    mkdir -p ${openstack_reposdir}
fi
generate_yum_config
generate_repos_config

## install utils
if ! rpm -q httpd createrepo yum-utils > /dev/null
then
    yum install -y httpd createrepo yum-utils
fi

## download all needed packages
destdir="${openstack_reposdir}/centos/7/x86_64"
packages=$(cat ${topdir}/packages | grep -v "^#")
${YUM} clean all
${YUMDOWNLOADER} --destdir ${destdir} ${packages}
createrepo --update -o ${destdir} ${destdir}

# restart apache
generate_apache_config
systemctl restart httpd.service
