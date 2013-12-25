#!/bin/bash
#
# Usage: dump-all-database-to-slave-node.sh <master ip address> <slave ip address>
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

## define password
mysql_root_password=${mysql_root_password:-nova}
mysql_repl_password=${mysql_repl_password:-nova}
##MYSQL="mysql -uroot -p${mysql_root_password}"
##MYSQLDUMP="mysqldump -uroot -p${mysql_root_password}"
MYSQL="mysql -uroot"
MYSQLDUMP="mysqldump -uroot"

# dump database to file
ssh root@${master_node} /bin/bash << EOF
echo "dumping all database to file..."
${MYSQLDUMP} --single-transaction --all-databases --master-data=1 > /tmp/master_backup.sql

## copy dumped database to slave node
echo "coping dumped database file..."
scp /tmp/master_backup.sql root@${slave_node}:/tmp/master_backup.sql
EOF

## import the dump file
ssh root@${slave_node} /bin/bash << EOF
${MYSQL} -e "STOP SLAVE"
${MYSQL} -e "CHANGE MASTER TO MASTER_HOST='${master_node}',MASTER_USER='replicator',MASTER_PASSWORD='${mysql_repl_password}'"
${MYSQL} -e "SOURCE /tmp/master_backup.sql"
${MYSQL} -e "START SLAVE"
${MYSQL} -e "SHOW SLAVE STATUS\G"
EOF
