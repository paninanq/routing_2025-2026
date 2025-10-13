#!/bin/sh
ip link add link eth2 name vlan10 type vlan id 10
ip addr add 172.10.10.10/24 dev vlan10
ip link set vlan10 up
udhcpc -i vlan10
ip route add 172.10.20.0/24 via 172.10.10.1 dev vlan10
