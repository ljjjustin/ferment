#!/bin/bash

if [ $# -ne 3 ]
then
    echo "usage: $0 <vip> <master ip> <slave ip>"
    exit
fi

service_ip=$1
slave_node=$3
master_node=$2
all_servers="${master_node} ${slave_node}"

## install keepalived & haproxy
for server in ${all_servers}
do
    ssh root@${server} /bin/bash <<EOF
## install keepalived & haproxy
if ! rpm -qa | grep 'keepalived' > /dev/null 2>&1
then
    yum install -y keepalived
fi
chkconfig keepalived on
if ! rpm -qa | grep 'haproxy' > /dev/null 2>&1
then
    yum install -y haproxy
fi
chkconfig haproxy on
if ! rpm -qa | grep 'rsyslog' > /dev/null 2>&1
then
    yum install -y rsyslog
fi
chkconfig rsyslog on
## modify sysctl config
if ! cat /etc/sysctl.conf | grep 'net.ipv4.ip_nonlocal_bind'
then
    echo "net.ipv4.ip_nonlocal_bind = 1" >> /etc/sysctl.conf
    sysctl -p > /dev/null 2>&1
fi
EOF
done

# generate haproxy config file
python generate-haproxy-config.py --vip ${service_ip} --servers ${master_node} --servers ${slave_node}

for server in ${all_servers}
do
    scp haproxy.cfg root@${server}:/etc/haproxy/haproxy.cfg
done

# generate keepalived config file for master node
python generate-keepalived-config.py --vip ${service_ip} --role MASTER
scp keepalived.conf root@${master_node}:/etc/keepalived/keepalived.conf

# generate keepalived config file for slave node
python generate-keepalived-config.py --vip ${service_ip} --role BACKUP
scp keepalived.conf root@${slave_node}:/etc/keepalived/keepalived.conf

cat > 50-haproxy.conf <<END
\$ModLoad imudp
\$UDPServerAddress 127.0.0.1
\$UDPServerRun 514

local1.* -/var/log/haproxy.log
& ~
END

# restart haproxy and keepalived
for server in ${all_servers}
do
    scp 50-haproxy.conf root@${server}:/etc/rsyslog.d/
    ssh root@${server} /bin/bash << EOF
# config rsyslog for haproxy
sed -i 's/SYSLOGD_OPTIONS=.*/SYSLOGD_OPTIONS="-r -c 2"/g' /etc/sysconfig/rsyslog

service rsyslog restart

if ps -e | grep 'haproxy' > /dev/null 2>&1
then
    service haproxy reload
else
    service haproxy restart
fi
sleep 3
if ps -e | grep 'keepalived' > /dev/null 2>&1
then
    service keepalived reload
else
    service keepalived restart
fi
EOF
done

rm -f haproxy.cfg 50-haproxy.conf keepalived.conf
