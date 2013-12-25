#!/bin/bash
#
# Usage: setup-master-slave-mysql-cluster.sh <master ip address> <slave ip address>
#
# Assumption:
#   1. you can ssh to the servers without password.

if [ $# -ne 2 ]
then
    echo "Usage: $0 <master ip address> <slave ip address>"
    exit
fi

master_node=$1
slave_node=$2
## define config file path and password
mysql_conf='/etc/my.cnf'
mysql_root_password=${mysql_root_password:-nova}
mysql_repl_password=${mysql_repl_password:-nova}
#MYSQL="mysql -uroot -p${mysql_root_password}"
MYSQL="mysql -uroot"

## install mysql server on all servers
for node in $@
do
    scp functions root@${node}:/tmp/functions
    ssh root@${node} /bin/bash << EOF
source /tmp/functions
have_setup_root_password='True'

## install and start mysql server
if rpm -qa | grep 'mysql-server' > /dev/null 2>&1
then
    service mysqld start && sleep 3
else
    yum install -y mysql-server
    chkconfig mysqld on
    have_setup_root_password='False'
fi

## modify mysql config file
if [ x"${node}" = x"${master_node}" ]
then
    iniset ${mysql_conf} mysqld bind-address ${master_node}
    iniset ${mysql_conf} mysqld max_connect_errors 3000
    iniset ${mysql_conf} mysqld server_id 10
    iniset ${mysql_conf} mysqld log_bin mysql-bin
    iniset ${mysql_conf} mysqld sync_binlog 1
elif [ x"${node}" = x"${slave_node}" ]
then
    iniset ${mysql_conf} mysqld bind-address ${slave_node}
    iniset ${mysql_conf} mysqld max_connect_errors 3000
    iniset ${mysql_conf} mysqld server_id 20
    iniset ${mysql_conf} mysqld log_bin mysql-bin
    iniset ${mysql_conf} mysqld log_slave_updates 1
    iniset ${mysql_conf} mysqld relay_log mysql-relay-bin
    iniset ${mysql_conf} mysqld read_only 1
fi

service mysqld restart && sleep 3
##if [ x"${have_setup_root_password}" = x"True" ]
##then
##    mysqladmin -uroot password ${mysql_root_password}
##fi
EOF
done

## setup mysql master node
ssh root@${master_node} /bin/bash << EOF
## create replication user
if ! ${MYSQL} -e "SELECT host, user from mysql.user" | grep replicator > /dev/null 2>&1
then
    ${MYSQL} -e "CREATE USER replicator IDENTIFIED BY '${mysql_repl_password}'"
    ${MYSQL} -e "GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'replicator'@'%' IDENTIFIED BY '${mysql_repl_password}'"
    ${MYSQL} -e "FLUSH PRIVILEGES"
fi
EOF
