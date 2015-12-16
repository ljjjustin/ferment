#!/usr/bin/env python

import argparse
import os
import sys
import time
import shutil

KEEPALIVED_HEADER = '''
global_defs {
	router_id OPENSTACK_HA
}

vrrp_script chk_haproxy {
	script "killall -0 haproxy"
	interval 1
}
'''

KEEPALIVED_INSTANCE='''
vrrp_instance openstack1 {
	state %(role)s
	interface %(dev)s
	priority %(priority)s
	virtual_router_id 51
	advert_int 1

	authentication {
		auth_type PASS
		auth_pass 123456
	}

	virtual_ipaddress {
		%(vip)s dev %(dev)s
	}

	track_script {
		chk_haproxy
	}
}
'''


if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser.add_argument('--role', metavar='server_role',
                        choices=['MASTER', 'BACKUP'],
                        required=True, help='Must be: MASTER or BACKUP')
    parser.add_argument('--vip', metavar='service_ip',
                        required=True, help='service ip')
    parser.add_argument('--sif', metavar='service_iface',
                        default='eth0', help='service interface')
    parser.add_argument('--hif', metavar='heartbeat_iface',
                        default='eth0', help='heartbeat interface')

    args = parser.parse_args()

    role = args.role
    service_ip = args.vip
    service_iface = args.sif
    heartbeat_iface = args.hif
    ## generate keepalived config file
    keepalived_conf = 'keepalived.conf'
    try:
        conf = file(keepalived_conf, 'w')
        conf.write(KEEPALIVED_HEADER)

        if role == 'MASTER':
            priority = 102
        else:
            priority = 101
        params = {
            'role': role,
            'priority': priority,
            'vip': service_ip,
            'dev': service_iface,
        }
        conf.write(KEEPALIVED_INSTANCE % params)
        conf.close()
    except IOError as e:
        print e
        exit(-1)
