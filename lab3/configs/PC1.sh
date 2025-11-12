#!/bin/sh
ip route del default via 172.10.0.1 dev eth0
udhcpc -i eth1