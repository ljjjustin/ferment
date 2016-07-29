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
yum_chroot_jail_dir="/opt/yum/chroot"
packages_topdir="${yum_chroot_jail_dir}/openstack/rpms"
packages_destdir="${packages_topdir}/centos/7/x86_64"
extra_repo_config="${yum_chroot_jail_dir}/etc/yum.repos.d/extra.repo"

## create rpm repository config
generate_repos_config()
{
    cat > ${extra_repo_config} << 'EOF'
[epel]
name=Extra Packages for Enterprise Linux 7 - $basearch
#baseurl=http://download.fedoraproject.org/pub/epel/7/$basearch
mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=$basearch
failovermethod=priority
enabled=1
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7

[mariadb]
name = MariaDB 10.2.0
baseurl = http://yum.mariadb.org/10.2.0/centos7-amd64
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
    DocumentRoot "${packages_topdir}"
    <Directory  "${packages_topdir}">
        Options +Indexes
        Require all granted
    </Directory>
    ErrorLog logs/repos-error.log
    CustomLog logs/repos-access.log common
</VirtualHost>
EOF
}

## create repostory base dir
if [ ! -d "${packages_destdir}" ]
then
    mkdir -p ${packages_destdir}
fi
generate_repos_config

## install utils
if ! rpm -q httpd createrepo > /dev/null
then
    yum install -y httpd createrepo
fi

## download all needed packages
cp "${topdir}/packages" "${packages_topdir}/packages"
cat > "${packages_topdir}/update.sh" << 'EOF'
#!/bin/bash

yumdownloader --resolv --destdir /openstack/rpms/centos/7/x86_64 $(cat /openstack/rpms/packages | grep -v '#')
EOF
chmod +x "${packages_topdir}/update.sh"
chroot "${yum_chroot_jail_dir}" "/openstack/rpms/update.sh"
createrepo --update -o ${packages_destdir} ${packages_destdir}

# restart apache
generate_apache_config
systemctl restart httpd.service
