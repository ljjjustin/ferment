#!/usr/bin/env python

import argparse
import os
import sys
import time
import shutil

SERVICES = {
    "glance": [9191, 9292],
    "keystone": [5000, 35357],
    "nova-api": [8773, 8774, 8775, 8776],
    "novncproxy": [6080],
}


HAPROXY_HEADER = '''
global
	log 127.0.0.1 local1 info
	log 127.0.0.1 local1 notice
	user haproxy
	group haproxy
	chroot  /var/lib/haproxy
	pidfile /var/run/haproxy.pid
	daemon
        ulimit-n 65000
	maxconn  30000
	# turn on stats unix socket
	stats socket /var/lib/haproxy/stats level admin

defaults
	log     global
	mode    tcp
	option  tcplog
	option  dontlognull
	option  redispatch
	retries 3
	maxconn 3000
	timeout queue           30s
	timeout connect         10s
	timeout client          30s
	timeout server          30s

listen admin_stats 0.0.0.0:1024
	mode http
	option httpchk
	option httplog
	option dontlognull
	balance roundrobin
	stats uri /stats
	stats auth admin:openstack
'''

HAPROXY_LISTEN_HEADER = '''\n
listen  %(service_name)s %(vip)s:%(port)s
	mode tcp
	option tcplog
	balance roundrobin'''

HAPROXY_LISTEN_SERVER = '''
	server %(server_name)s %(ip)s:%(port)s check inter 5000 rise 2 fall 3'''


if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser.add_argument('--vip', metavar='service_ip',
                        required=True, help='service ip')
    parser.add_argument('--servers', metavar='server_list',
                        required=True, action='append',
                        help='ip address of real server')
    parser.add_argument('--output', metavar='output_config_file',
                        default='haproxy.cfg', help='output to which file')

    args = parser.parse_args()

    service_ip = args.vip
    haproxy_conf = args.output
    servers = set()
    for server_list in args.servers:
        for server in server_list.split(','):
            servers.add(server)

    servers = sorted(servers)

    ## generate haproxy config file
    try:
        conf = file(haproxy_conf, 'w')
        conf.write(HAPROXY_HEADER)

        for service in SERVICES.keys():
            ports = SERVICES[service]
            for n, port in enumerate(ports, 1):
                service_name = "%s-%i" % (service, port)
                listen_params = {
                    'service_name': service_name,
                    'vip': service_ip,
                    'port': port,
                }
                conf.write(HAPROXY_LISTEN_HEADER % listen_params)
                for i, server in enumerate(servers, 1):
                    server_name = "controller-%i" % i
                    server_params = {
                        'server_name': server_name,
                        'ip': server,
                        'port': port,
                    }
                    conf.write(HAPROXY_LISTEN_SERVER % server_params)

        conf.close()
    except IOError as e:
        print e
        exit(-1)
