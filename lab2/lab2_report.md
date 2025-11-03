# Лабораторная работа №1

## Задание

<https://itmo-ict-faculty.github.io/introduction-in-routing/education/labs2023_2024/lab2/lab2/>


### Топология

```
name: lab2
mgmt:
  network: lab-2
  ipv4-subnet: 172.10.0.0/24

topology:
  kinds:
    vr-ros:
      image: vrnetlab/mikrotik_routeros:6.47.9

  nodes:
    R01.BRL:
      kind: vr-ros
      mgmt-ipv4: 172.10.0.103
      startup-config: configs/R01.BRL.rsc
    R01.FRT:
      kind: vr-ros
      mgmt-ipv4: 172.10.0.102
      startup-config: configs/R01.FRT.rsc
    R01.MSK:
      kind: vr-ros
      mgmt-ipv4: 172.10.0.101
      startup-config: configs/R01.MSK.rsc
    PC1:
      kind: linux
      image: alpine:latest
      mgmt-ipv4: 172.10.0.2
      binds:
        - ./configs:/configs
      exec:
        - sh /configs/PC.sh
    PC2:
      kind: linux
      image: alpine:latest
      mgmt-ipv4: 172.10.0.3
      binds:
        - ./configs:/configs
      exec:
        - sh /configs/PC.sh
    PC3:
      kind: linux
      image: alpine:latest
      mgmt-ipv4: 172.10.0.4
      binds:
        - ./configs:/configs
      exec:
        - sh /configs/PC.sh

  links:
    - endpoints: ["R01.BRL:eth1","R01.MSK:eth2"]
    - endpoints: ["R01.BRL:eth2","R01.FRT:eth1"]
    - endpoints: ["R01.MSK:eth1","R01.FRT:eth2"]
    - endpoints: ["R01.MSK:eth3","PC1:eth1"]
    - endpoints: ["R01.FRT:eth3","PC2:eth1"]
    - endpoints: ["R01.BRL:eth3","PC3:eth1"]
```

Ниже представлена схема сети в draw.io:

![Схема сети в draw.io](images/driwio.png)



### Настройка маршрутизаторов

Данные команды настраивают маршрутизатор MikroTik с именем R01.BRL, добавляют IP-адреса на интерфейсы, настраивают DHCP-сервер для сети 10.10.0.0/16, задают статические маршруты до сетей 10.30.0.0/16 и 10.20.0.0/16, а также создают пользователя paninanq с полными правами, удаляя стандартного администратора.

```
/ip pool
add name=dhcp-pool ranges=10.10.0.10-10.10.255.254
/ip dhcp-server
add address-pool=dhcp-pool disabled=no interface=ether4 name=dhcp-server
/ip dhcp-server network
add address=10.10.0.0/16 gateway=10.10.0.1
/ip address
add address=192.168.28.1/30 interface=ether2
add address=192.168.29.2/30 interface=ether3
add address=10.10.0.1/16 interface=ether4
/ip route
add distance=1 dst-address=10.30.0.0/16 gateway=192.168.28.2
add distance=1 dst-address=10.20.0.0/16 gateway=192.168.29.1
/user
add name=paninanq password=paninanq group=full
remove admin
/system identity
set name=R01.BRL
```

Маршрутизаторы R01.MSK и R01.FRT настраиваются аналогично, соответственно схеме drawio.


### Настройка ПК

Данные команды удаляют маршрут по умолчанию через eth0 и получают новый IP-адрес по DHCP на интерфейсе eth1.

```
#!/bin/sh
ip route del default via 172.10.0.1 dev eth0
udhcpc -i eth1
```

### Результат работы

При деплое сети получаем:

`containerlab deploy`

```
containerlab deploy
00:03:48 INFO Containerlab started version=0.70.2
00:03:48 INFO Parsing & checking topology file=lab-2.clab.yaml
00:03:48 INFO Creating docker network name=lab-2 IPv4 subnet=172.10.0.0/24 IPv6 subnet="" MTU=0
00:03:48 INFO Creating lab directory path=/home/paninanq/sem-5/2025_2026-introduction_in_routing-k3323-panina_a_s/lab2/clab-lab2
00:03:48 INFO Creating container name=PC1
00:03:48 INFO Creating container name=R01.MSK
00:03:48 INFO Creating container name=PC3
00:03:48 INFO Creating container name=R01.FRT
00:03:48 INFO Creating container name=R01.BRL
00:03:48 INFO Creating container name=PC2
00:03:49 INFO Created link: R01.MSK:eth3 ▪┄┄▪ PC1:eth1
00:03:49 INFO Created link: R01.BRL:eth1 ▪┄┄▪ R01.MSK:eth2
00:03:49 INFO Created link: R01.BRL:eth2 ▪┄┄▪ R01.FRT:eth1
00:03:49 INFO Created link: R01.MSK:eth1 ▪┄┄▪ R01.FRT:eth2
00:03:49 INFO Created link: R01.BRL:eth3 ▪┄┄▪ PC3:eth1
00:03:49 INFO Created link: R01.FRT:eth3 ▪┄┄▪ PC2:eth1
00:05:00 INFO Executed command node=PC2 command="sh /configs/PC.sh" stdout=""
00:05:00 INFO Executed command node=PC1 command="sh /configs/PC.sh" stdout=""
00:05:00 INFO Executed command node=PC3 command="sh /configs/PC.sh" stdout=""
00:05:00 INFO Adding host entries path=/etc/hosts
00:05:00 INFO Adding SSH config for nodes path=/etc/ssh/ssh_config.d/clab-lab2.conf
🎉 A newer containerlab version (0.71.0) is available!
Release notes: https://containerlab.dev/rn/0.71/
Run 'sudo clab version upgrade' or see https://containerlab.dev/install/ for installation options.
╭───────────────────┬───────────────────────────────────┬───────────┬────────────────╮
│        Name       │             Kind/Image            │   State   │ IPv4/6 Address │
├───────────────────┼───────────────────────────────────┼───────────┼────────────────┤
│ clab-lab2-PC1     │ linux                             │ running   │ 172.10.0.2     │
│                   │ alpine:latest                     │           │ N/A            │
├───────────────────┼───────────────────────────────────┼───────────┼────────────────┤
│ clab-lab2-PC2     │ linux                             │ running   │ 172.10.0.3     │
│                   │ alpine:latest                     │           │ N/A            │
├───────────────────┼───────────────────────────────────┼───────────┼────────────────┤
│ clab-lab2-PC3     │ linux                             │ running   │ 172.10.0.4     │
│                   │ alpine:latest                     │           │ N/A            │
├───────────────────┼───────────────────────────────────┼───────────┼────────────────┤
│ clab-lab2-R01.BRL │ vr-ros                            │ running   │ 172.10.0.103   │
│                   │ vrnetlab/mikrotik_routeros:6.47.9 │ (healthy) │ N/A            │
├───────────────────┼───────────────────────────────────┼───────────┼────────────────┤
│ clab-lab2-R01.FRT │ vr-ros                            │ running   │ 172.10.0.102   │
│                   │ vrnetlab/mikrotik_routeros:6.47.9 │ (healthy) │ N/A            │
├───────────────────┼───────────────────────────────────┼───────────┼────────────────┤
│ clab-lab2-R01.MSK │ vr-ros                            │ running   │ 172.10.0.101   │
│                   │ vrnetlab/mikrotik_routeros:6.47.9 │ (healthy) │ N/A            │
╰───────────────────┴───────────────────────────────────┴───────────┴────────────────╯

```

Ниже представлены доказательства того, что компьютеры получили ip адреса с помощью dhcp в правильных вланах и между ними есть связь.

```
docker exec -it clab-lab2-PC1 sh
/ # ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
121: eth0@if122: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue state UP 
    link/ether 02:42:ac:0a:00:02 brd ff:ff:ff:ff:ff:ff
    inet 172.10.0.2/24 brd 172.10.0.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::42:acff:fe0a:2/64 scope link 
       valid_lft forever preferred_lft forever
132: eth1@if131: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 9500 qdisc noqueue state UP 
    link/ether aa:c1:ab:dc:e5:37 brd ff:ff:ff:ff:ff:ff
    inet 10.30.255.254/16 scope global eth1
       valid_lft forever preferred_lft forever
    inet6 fe80::a8c1:abff:fedc:e537/64 scope link 
       valid_lft forever preferred_lft forever
/ # exit
paninanq@paninanq-BOM-WXX9:~/sem-5/2025_2026-introduction_in_routing-k3323-panina_a_s/lab2$ docker exec -it clab-lab2-PC2 sh
/ # ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
123: eth0@if124: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue state UP 
    link/ether 02:42:ac:0a:00:03 brd ff:ff:ff:ff:ff:ff
    inet 172.10.0.3/24 brd 172.10.0.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::42:acff:fe0a:3/64 scope link 
       valid_lft forever preferred_lft forever
136: eth1@if135: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 9500 qdisc noqueue state UP 
    link/ether aa:c1:ab:c8:eb:f7 brd ff:ff:ff:ff:ff:ff
    inet 10.20.255.254/16 scope global eth1
       valid_lft forever preferred_lft forever
    inet6 fe80::a8c1:abff:fec8:ebf7/64 scope link 
       valid_lft forever preferred_lft forever
/ # exit
paninanq@paninanq-BOM-WXX9:~/sem-5/2025_2026-introduction_in_routing-k3323-panina_a_s/lab2$ docker exec -it clab-lab2-PC3 sh
/ # ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
119: eth0@if120: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue state UP 
    link/ether 02:42:ac:0a:00:04 brd ff:ff:ff:ff:ff:ff
    inet 172.10.0.4/24 brd 172.10.0.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::42:acff:fe0a:4/64 scope link 
       valid_lft forever preferred_lft forever
134: eth1@if133: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 9500 qdisc noqueue state UP 
    link/ether aa:c1:ab:8c:6c:ad brd ff:ff:ff:ff:ff:ff
    inet 10.10.255.254/16 scope global eth1
       valid_lft forever preferred_lft forever
    inet6 fe80::a8c1:abff:fe8c:6cad/64 scope link 
       valid_lft forever preferred_lft forever
/ # ping 10.20.255.254
PING 10.20.255.254 (10.20.255.254): 56 data bytes
64 bytes from 10.20.255.254: seq=0 ttl=62 time=1.881 ms
64 bytes from 10.20.255.254: seq=1 ttl=62 time=1.359 ms
64 bytes from 10.20.255.254: seq=2 ttl=62 time=1.714 ms
^C
--- 10.20.255.254 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 1.359/1.651/1.881 ms
/ # ping 10.30.255.254
PING 10.30.255.254 (10.30.255.254): 56 data bytes
64 bytes from 10.30.255.254: seq=0 ttl=62 time=1.919 ms
64 bytes from 10.30.255.254: seq=1 ttl=62 time=1.817 ms
64 bytes from 10.30.255.254: seq=2 ttl=62 time=1.844 ms
^C
--- 10.30.255.254 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 1.817/1.860/1.919 ms
```

## Заключение
В результате работы была создана сеть связи в трех геораспределенных офисах.