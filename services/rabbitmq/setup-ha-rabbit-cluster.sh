#!/bin/bash
#
# Usage: setup-ha-rabbit-cluster.sh <server1> <server2>
#
# Assumption:
#   1. you can ssh to the servers without password.
#   2. the servers can connect to the Internet and you have setup the right yum repository.
#   3. you have setup the hostname properly.

if [ $# -ne 2 ]
then
    echo "Usage: $0 <server1> <server2>"
    exit
fi

## define config file path
rabbit_conf='/etc/rabbitmq/rabbitmq.config'
rabbit_env_conf='/etc/rabbitmq/rabbitmq-env.conf'

## generate rabbit node list
master_node=$1
master_hostname=''
rabbit_nodes=''
for node in $@
do
    hostname=$(ssh root@${node} 'hostname -s')
    if [ x"${rabbit_nodes}" = "x" ]
    then
        rabbit_nodes="'${hostname}'"
        master_hostname="${hostname}"
    else
        rabbit_nodes="${rabbit_nodes}, '${hostname}'"
    fi
done

## install and stop each rabbit node
for node in $@
do
    ssh root@${node} /bin/bash << EOF
## install rabbitmq-server
if ! rpm -qa | grep 'rabbitmq-server' > /dev/null 2>&1
then
    yum install -y rabbitmq-server
fi
chkconfig rabbitmq-server on

if netstat -ntlp | grep -w '5672' > /dev/null 2>&1
then
    service rabbitmq-server stop
fi
if netstat -ntlp | grep -w '5672' > /dev/null 2>&1
then
    killall beam.smp
fi
EOF
done

## get erlang cookie
erlang_cookie=$(ssh root@${master_node} 'cat /var/lib/rabbitmq/.erlang.cookie')
if [ x"${erlang_cookie}" = "x" ]
then
    erlang_cookie=$(cat /dev/urandom | head -1 | md5sum | cut -c 20)
fi

## setup erlang cookie
for node in $@
do
    ssh root@${node} /bin/bash << EOF
echo -n ${erlang_cookie} > /var/lib/rabbitmq/.erlang.cookie
EOF
done

## join the same rabbit cluster
for node in $@
do
    ssh root@${node} /bin/bash << EOF
## create config file
cat > ${rabbit_env_conf} << END
RABBITMQ_CONFIG_FILE=/etc/rabbitmq/rabbitmq
RABBITMQ_NODE_IP_ADDRESS=${node}
END

cat > ${rabbit_conf} << END
[
    {rabbit, [{cluster_nodes, {[${rabbit_nodes}], disc}}]}
].
END

service rabbitmq-server start
if [ x"${node}" != x"${master_node}" ]
then
    rabbitmqctl stop_app
    rabbitmqctl reset
    rabbitmqctl join_cluster rabbit@${master_hostname}
    rabbitmqctl start_app
fi

## show rabbit cluster status
rabbitmqctl cluster_status

## set HA policy
##rabbitmqctl set_policy HA '^(?!amq\.).*' '{"ha-mode": "all", "ha-sync-mode": "automatic"}'

EOF
done
