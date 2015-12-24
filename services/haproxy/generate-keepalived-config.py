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
	virtual_router_id %(vrouter_id)s
	interface %(dev)s
	state BACKUP
	priority 100
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
    parser.add_argument('--vrouter-id', metavar='virtual router id',
                        default=51, help='Must between: 0~255')
    parser.add_argument('--vip', metavar='service_ip',
                        required=True, help='service ip')
    parser.add_argument('--sif', metavar='service_iface',
                        default='eth0', help='service interface')
    parser.add_argument('--hif', metavar='heartbeat_iface',
                        default='eth0', help='heartbeat interface')

    args = parser.parse_args()

    vrouter_id = args.vrouter_id
    service_ip = args.vip
    service_iface = args.sif
    heartbeat_iface = args.hif
    ## generate keepalived config file
    keepalived_conf = 'keepalived.conf'
    try:
        conf = file(keepalived_conf, 'w')
        conf.write(KEEPALIVED_HEADER)

        params = {
            'vrouter_id': vrouter_id,
            'vip': service_ip,
            'dev': service_iface,
        }
        conf.write(KEEPALIVED_INSTANCE % params)
        conf.close()
    except IOError as e:
        print e
        exit(-1)
