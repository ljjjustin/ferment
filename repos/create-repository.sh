#!/bin/bash

topdir=$(cd $(dirname $0) && pwd)

## config openstack repo
openstack_reposdir="/tmp/openstack"
yum_config_file="${openstack_reposdir}/yum.conf"
repo_config_file="${openstack_reposdir}/openstack.repo"

mkdir -p ${openstack_reposdir}

cat > ${yum_config_file} << EOF
[main]
cachedir=/var/cache/yum/\$basearch/\$releasever
keepcache=0
debuglevel=2
exactarch=1
obsoletes=1
plugins=0
gpgcheck=0
installonly_limit=5
reposdir=${openstack_reposdir}
logfile=${openstack_reposdir}/yum.log
EOF

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

[openstack-liberty]
name=OpenStack Liberty Repository
baseurl=http://mirror.centos.org/centos/7/cloud/$basearch/openstack-liberty/
enabled=1
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Cloud
EOF

YUM="yum -c ${yum_config_file}"
YUMDOWNLOADER="yumdownloader -c ${yum_config_file} -y --resolve"
## install createrepo & yumdownloader
${YUM} clean all
${YUM} install -y httpd createrepo yum-utils

## download all necessary packages
destdir="${openstack_reposdir}/centos/6/x86_64"
packages=$(cat ${topdir}/packages | grep -v "^#")
${YUMDOWNLOADER} --destdir ${destdir} ${packages}
createrepo --update -o ${destdir} ${destdir}

## create httpd config
cat > /etc/httpd/conf.d/000-repo.conf <<EOF
<VirtualHost *:80>
    ServerAdmin admin@autonavi.com
    ServerName mirrors.autonavi.com
    DocumentRoot "${openstack_reposdir}"
    <Directory "${openstack_reposdir}">
        Options Indexes FollowSymLinks MultiViews
        AllowOverride None
        Order allow,deny
        Allow from all
    </Directory>
    ErrorLog logs/repository-error_log
    CustomLog logs/repository-access_log common
</VirtualHost>
EOF
systemctl restart httpd.service