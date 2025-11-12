# Лабораторная работа №3

## Задание

<https://itmo-ict-faculty.github.io/introduction-in-routing/education/labs2023_2024/lab3/lab3/>


### Топология

```
name: lab3
mgmt:
  network: lab-3
  ipv4-subnet: 172.10.0.0/24

topology:

  nodes:
    R01.SPB:
      kind: vr-mikrotik_ros
      image: vrnetlab/mikrotik_routeros:6.47.9
      mgmt-ipv4: 172.10.0.101
      startup-config: configs/R01.SPB.rsc
    R01.HKI:
      kind: vr-mikrotik_ros
      image: vrnetlab/mikrotik_routeros:6.47.9
      mgmt-ipv4: 172.10.0.102
      startup-config: configs/R01.HKI.rsc
    R01.MSK:
      kind: vr-mikrotik_ros
      image: vrnetlab/mikrotik_routeros:6.47.9
      mgmt-ipv4: 172.10.0.103
      startup-config: configs/R01.MSK.rsc
    R01.LND:
      kind: vr-mikrotik_ros
      image: vrnetlab/mikrotik_routeros:6.47.9
      mgmt-ipv4: 172.10.0.104
      startup-config: configs/R01.LND.rsc
    R01.LBN:
      kind: vr-mikrotik_ros
      image: vrnetlab/mikrotik_routeros:6.47.9
      mgmt-ipv4: 172.10.0.105
      startup-config: configs/R01.LBN.rsc
    R01.NY:
      kind: vr-mikrotik_ros
      image: vrnetlab/mikrotik_routeros:6.47.9
      mgmt-ipv4: 172.10.0.106
      startup-config: configs/R01.NY.rsc
    PC1:
      kind: linux
      image: alpine:latest
      mgmt-ipv4: 172.10.0.2
      binds:
        - ./configs:/configs
      exec:
        - sh /configs/PC1.sh
    SGI-PRISM:
      kind: linux
      image: alpine:latest
      mgmt-ipv4: 172.10.0.3
      binds:
        - ./configs:/configs
      exec:
        - sh /configs/SGI-PRISM.sh


  links:
    - endpoints: ["R01.SPB:eth1","R01.HKI:eth1"]
    - endpoints: ["R01.SPB:eth2","R01.MSK:eth1"]
    - endpoints: ["R01.SPB:eth3","PC1:eth1"]
    - endpoints: ["R01.HKI:eth3","R01.LBN:eth3"]
    - endpoints: ["R01.HKI:eth2","R01.LND:eth1"]
    - endpoints: ["R01.MSK:eth2","R01.LBN:eth1"]
    - endpoints: ["R01.LND:eth2","R01.NY:eth1"]
    - endpoints: ["R01.LBN:eth2","R01.NY:eth2"]
    - endpoints: ["R01.NY:eth3", "SGI-PRISM:eth1"]
```

Ниже представлена схема сети в draw.io:

![Схема сети в draw.io](images/driwio.png)



### Настройка маршрутизаторов

Данная конфигурация настраивает маршрутизатор MikroTik R01.LBN: назначаются IP-адреса на интерфейсы ether2-ether4 (10.10.6.2/30, 10.10.4.1/30, 10.10.5.2/30), создается bridge-интерфейс loopback с адресом 10.255.255.5/32, настраивается OSPF-инстанс inst с router-id 10.255.255.5, который анонсирует сети 10.10.4.0/30, 10.10.5.0/30, 10.10.6.0/30 и loopback-адрес в области backbonev28. Также включается редистрибуция маршрутов, так как без нее ospf знает о маршрутах, но не рассказывает соседям о них. Настраивается MPLS LDP с transport-адресом 10.255.255.5, который работает на интерфейсах ether2-ether4 с фильтрами на прием и отдачу изформации соседям только из сети 10.255.255.0/24. Ну и создается пользователь paninanq с полными правами доступа вместо admin. Аналогичная настройка выполнена на R01.HKI, R01.LND, R01.MSK соответственно схеме driwio.

```
/ip address
add address=10.10.6.2/30 interface=ether2
add address=10.10.4.1/30 interface=ether3
add address=10.10.5.2/30 interface=ether4

/interface bridge
add name=loopback
/ip address 
add address=10.255.255.5/32 interface=loopback network=10.255.255.5

/routing ospf instance
add name=inst router-id=10.255.255.5
set inst redistribute-connected=as-type-1
/routing ospf area
add name=backbonev28 area-id=0.0.0.0 instance=inst
/routing ospf network
add area=backbonev28 network=10.10.5.0/30
add area=backbonev28 network=10.10.4.0/30
add area=backbonev28 network=10.10.6.0/30
add area=backbonev28 network=10.255.255.5/32
/routing ospf instance set inst redistribute-connected=as-type-1

/mpls ldp
set lsr-id=10.255.255.5
set enabled=yes transport-address=10.255.255.5
/mpls ldp advertise-filter 
add prefix=10.255.255.0/24 advertise=yes
add advertise=no
/mpls ldp accept-filter 
add prefix=10.255.255.0/24 accept=yes
add accept=no
/mpls ldp interface
add interface=ether2
add interface=ether3
add interface=ether4

/user
add name=paninanq password=paninanq group=full
remove admin
/system identity
set name=R01.LBN
```

Настройка R01.SPB и R01.NY представлена ниже.

R01.SPB

```
/ip address
add address=10.10.1.1/30 interface=ether2
add address=10.10.7.1/30 interface=ether3
add address=192.168.28.1/24 interface=ether4

/ip pool
add name=dhcp-pool ranges=192.168.28.10-192.168.28.100
/ip dhcp-server
add address-pool=dhcp-pool disabled=no interface=ether4 name=dhcp-server
/ip dhcp-server network
add address=192.168.28.0/24 gateway=192.168.28.1

/interface bridge
add name=loopback
/ip address 
add address=10.255.255.2/32 interface=loopback network=10.255.255.2

/routing ospf instance
add name=inst router-id=10.255.255.2
set inst redistribute-connected=as-type-1
/routing ospf area
add name=backbonev28 area-id=0.0.0.0 instance=inst
/routing ospf network
add area=backbonev28 network=10.10.1.0/30
add area=backbonev28 network=10.10.7.0/30
add area=backbonev28 network=192.168.28.0/24
add area=backbonev28 network=10.255.255.2/32

/mpls ldp
set lsr-id=10.255.255.2
set enabled=yes transport-address=10.255.255.2
/mpls ldp advertise-filter 
add prefix=10.255.255.0/24 advertise=yes
add advertise=no
/mpls ldp accept-filter 
add prefix=10.255.255.0/24 accept=yes
add accept=no
/mpls ldp interface
add interface=ether2
add interface=ether3
add interface=ether4

/interface bridge
add name=vpn
/interface vpls
add disabled=no name=SGIPC remote-peer=10.255.255.7 cisco-style=yes cisco-style-id=0
/interface bridge port
add interface=SGIPC bridge=vpn

/user
add name=paninanq password=paninanq group=full
remove admin
/system identity
set name=R01.SPB
```

R01.NY

```
/ip address
add address=10.10.3.2/30 interface=ether2
add address=10.10.4.2/30 interface=ether3
add address=192.168.14.1/24 interface=ether4

/ip pool
add name=dhcp-pool ranges=192.168.14.10-192.168.14.100
/ip dhcp-server
add address-pool=dhcp-pool disabled=no interface=ether4 name=dhcp-server
/ip dhcp-server network
add address=192.168.14.0/24 gateway=192.168.14.1

/interface bridge
add name=loopback
/ip address 
add address=10.255.255.7/32 interface=loopback network=10.255.255.7

/routing ospf instance
add name=inst router-id=10.255.255.7
set inst redistribute-connected=as-type-1
/routing ospf area
add name=backbonev28 area-id=0.0.0.0 instance=inst
/routing ospf network
add area=backbonev28 network=10.10.4.0/30
add area=backbonev28 network=10.10.3.0/30
add area=backbonev28 network=192.168.14.0/24
add area=backbonev28 network=10.255.255.7/32
/routing ospf instance set inst redistribute-connected=as-type-1

/mpls ldp
set lsr-id=10.255.255.7
set enabled=yes transport-address=10.255.255.7
/mpls ldp advertise-filter 
add prefix=10.255.255.0/24 advertise=yes
add advertise=no
/mpls ldp accept-filter 
add prefix=10.255.255.0/24 accept=yes
add accept=no
/mpls ldp interface
add interface=ether2
add interface=ether3
add interface=ether4

/interface bridge
add name=vpn
/interface vpls
add disabled=no name=SGIPC remote-peer=10.255.255.2 cisco-style=yes cisco-style-id=0
/interface bridge port
add interface=SGIPC bridge=vpn

/user
add name=paninanq password=paninanq group=full
remove admin
/system identity
set name=R01.NY
```

Настройка этих устройств отличается от предыдущих тем, что добавлен dhcp-сервер для раздачи IP устройствам и создан EoMPLS-туннель SGIPC до удаленного пира, который добавляется в bridge vpn для организации L2-соединения.


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
22:13:33 INFO Containerlab started version=0.70.2
22:13:33 INFO Parsing & checking topology file=lab-3.clab.yaml
22:13:33 INFO Destroying lab name=lab3
22:13:33 INFO Removed container name=clab-lab3-SGI-PRISM
22:13:34 INFO Removed container name=clab-lab3-PC1
22:13:34 INFO Removed container name=clab-lab3-R01.LND
22:13:34 INFO Removed container name=clab-lab3-R01.HKI
22:13:34 INFO Removed container name=clab-lab3-R01.SPB
22:13:34 INFO Removed container name=clab-lab3-R01.NY
22:13:34 INFO Removed container name=clab-lab3-R01.MSK
22:13:34 INFO Removed container name=clab-lab3-R01.LBN
22:13:34 INFO Removing host entries path=/etc/hosts
22:13:34 INFO Removing SSH config path=/etc/ssh/ssh_config.d/clab-lab3.conf
22:13:34 INFO Removing directory path=/home/paninanq/sem-5/2025_2026-introduction_in_routing-k3323-panina_a_s/lab3/clab-lab3
22:13:34 INFO Creating lab directory path=/home/paninanq/sem-5/2025_2026-introduction_in_routing-k3323-panina_a_s/lab3/clab-lab3
22:13:34 INFO Creating container name=SGI-PRISM
22:13:34 INFO Creating container name=PC1
22:13:34 INFO Creating container name=R01.MSK
22:13:34 INFO Creating container name=R01.NY
22:13:34 INFO Creating container name=R01.SPB
22:13:34 INFO Creating container name=R01.HKI
22:13:34 INFO Creating container name=R01.LND
22:13:34 INFO Creating container name=R01.LBN
22:13:35 INFO Created link: R01.LBN:eth2 ▪┄┄▪ R01.NY:eth2
22:13:35 INFO Created link: R01.NY:eth3 ▪┄┄▪ SGI-PRISM:eth1
22:13:35 INFO Created link: R01.SPB:eth2 ▪┄┄▪ R01.MSK:eth1
22:13:35 INFO Created link: R01.MSK:eth2 ▪┄┄▪ R01.LBN:eth1
22:13:36 INFO Created link: R01.SPB:eth3 ▪┄┄▪ PC1:eth1
22:13:36 INFO Created link: R01.SPB:eth1 ▪┄┄▪ R01.HKI:eth1
22:13:36 INFO Created link: R01.HKI:eth3 ▪┄┄▪ R01.LBN:eth3
22:13:36 INFO Created link: R01.LND:eth2 ▪┄┄▪ R01.NY:eth1
22:13:36 INFO Created link: R01.HKI:eth2 ▪┄┄▪ R01.LND:eth1
22:14:46 INFO Executed command node=PC1 command="sh /configs/PC1.sh" stdout=""
22:14:46 INFO Executed command node=SGI-PRISM command="sh /configs/SGI-PRISM.sh" stdout=""
22:14:47 INFO Adding host entries path=/etc/hosts
22:14:47 INFO Adding SSH config for nodes path=/etc/ssh/ssh_config.d/clab-lab3.conf
🎉 A newer containerlab version (0.71.1) is available!
Release notes: https://containerlab.dev/rn/0.71/#0711
Run 'sudo clab version upgrade' or see https://containerlab.dev/install/ for installation options.
╭─────────────────────┬───────────────────────────────────┬───────────┬────────────────╮
│         Name        │             Kind/Image            │   State   │ IPv4/6 Address │
├─────────────────────┼───────────────────────────────────┼───────────┼────────────────┤
│ clab-lab3-PC1       │ linux                             │ running   │ 172.10.0.2     │
│                     │ alpine:latest                     │           │ N/A            │
├─────────────────────┼───────────────────────────────────┼───────────┼────────────────┤
│ clab-lab3-R01.HKI   │ vr-mikrotik_ros                   │ running   │ 172.10.0.102   │
│                     │ vrnetlab/mikrotik_routeros:6.47.9 │ (healthy) │ N/A            │
├─────────────────────┼───────────────────────────────────┼───────────┼────────────────┤
│ clab-lab3-R01.LBN   │ vr-mikrotik_ros                   │ running   │ 172.10.0.105   │
│                     │ vrnetlab/mikrotik_routeros:6.47.9 │ (healthy) │ N/A            │
├─────────────────────┼───────────────────────────────────┼───────────┼────────────────┤
│ clab-lab3-R01.LND   │ vr-mikrotik_ros                   │ running   │ 172.10.0.104   │
│                     │ vrnetlab/mikrotik_routeros:6.47.9 │ (healthy) │ N/A            │
├─────────────────────┼───────────────────────────────────┼───────────┼────────────────┤
│ clab-lab3-R01.MSK   │ vr-mikrotik_ros                   │ running   │ 172.10.0.103   │
│                     │ vrnetlab/mikrotik_routeros:6.47.9 │ (healthy) │ N/A            │
├─────────────────────┼───────────────────────────────────┼───────────┼────────────────┤
│ clab-lab3-R01.NY    │ vr-mikrotik_ros                   │ running   │ 172.10.0.106   │
│                     │ vrnetlab/mikrotik_routeros:6.47.9 │ (healthy) │ N/A            │
├─────────────────────┼───────────────────────────────────┼───────────┼────────────────┤
│ clab-lab3-R01.SPB   │ vr-mikrotik_ros                   │ running   │ 172.10.0.101   │
│                     │ vrnetlab/mikrotik_routeros:6.47.9 │ (healthy) │ N/A            │
├─────────────────────┼───────────────────────────────────┼───────────┼────────────────┤
│ clab-lab3-SGI-PRISM │ linux                             │ running   │ 172.10.0.3     │
│                     │ alpine:latest                     │           │ N/A            │
╰─────────────────────┴───────────────────────────────────┴───────────┴────────────────╯

```

Ниже представлены доказательства того, что маршруты прописаны динамически с помощью OSPF.

```
[paninanq@R01.HKI] > ip route print 
Flags: X - disabled, A - active, D - dynamic, C - connect, S - static, r - rip, b - bgp, o - ospf, m - mme, 
B - blackhole, U - unreachable, P - prohibit 
 #      DST-ADDRESS        PREF-SRC        GATEWAY            DISTANCE
 0 ADC  10.10.1.0/30       10.10.1.2       ether2                    0
 1 ADC  10.10.2.0/30       10.10.2.1       ether3                    0
 2 ADo  10.10.3.0/30                       10.10.2.2               110
 3 ADo  10.10.4.0/30                       10.10.5.2               110
 4 ADC  10.10.5.0/30       10.10.5.1       ether4                    0
 5 ADo  10.10.6.0/30                       10.10.5.2               110
 6 ADo  10.10.7.0/30                       10.10.1.1               110
 7 ADo  10.255.255.2/32                    10.10.1.1               110
 8 ADC  10.255.255.3/32    10.255.255.3    loopback                  0
 9 ADo  10.255.255.4/32                    10.10.5.2               110
                                           10.10.1.1         
10 ADo  10.255.255.5/32                    10.10.5.2               110
11 ADo  10.255.255.6/32                    10.10.2.2               110
12 ADo  10.255.255.7/32                    10.10.5.2               110
                                           10.10.2.2         
13 ADC  172.31.255.28/30   172.31.255.30   ether1                    0
14 ADo  192.168.14.0/24                    10.10.5.2               110

[paninanq@R01.MSK] > ip route print 
Flags: X - disabled, A - active, D - dynamic, C - connect, S - static, r - rip, b - bgp, o - ospf, m - mme, 
B - blackhole, U - unreachable, P - prohibit 
 #      DST-ADDRESS        PREF-SRC        GATEWAY            DISTANCE
 0 ADo  10.10.1.0/30                       10.10.7.1               110
 1 ADo  10.10.2.0/30                       10.10.6.2               110
                                           10.10.7.1         
 2 ADo  10.10.3.0/30                       10.10.6.2               110
 3 ADo  10.10.4.0/30                       10.10.6.2               110
 4 ADo  10.10.5.0/30                       10.10.6.2               110
 5 ADC  10.10.6.0/30       10.10.6.1       ether3                    0
 6 ADC  10.10.7.0/30       10.10.7.2       ether2                    0
 7 ADo  10.255.255.2/32                    10.10.7.1               110
 8 ADo  10.255.255.3/32                    10.10.6.2               110
                                           10.10.7.1         
 9 ADC  10.255.255.4/32    10.255.255.4    loopback                  0
10 ADo  10.255.255.5/32                    10.10.6.2               110
11 ADo  10.255.255.6/32                    10.10.6.2               110
                                           10.10.7.1         
12 ADo  10.255.255.7/32                    10.10.6.2               110
13 ADC  172.31.255.28/30   172.31.255.30   ether1                    0
```

Так же работает MPLS:

```
[paninanq@R01.HKI] > mpls forwarding-table print 
Flags: H - hw-offload, L - ldp, V - vpls, T - traffic-eng 
 #    IN-LABEL                        OUT-LABELS                    DESTINATION                    INTERFACE                    NEXTHOP        
 0    expl-null                      
 1  L 16                                                            10.255.255.2/32                ether2                       10.10.1.1      
 2  L 17                              16                            10.255.255.7/32                ether4                       10.10.5.2      
 3  L 18                                                            10.255.255.6/32                ether3                       10.10.2.2      
 4  L 19                              18                            10.255.255.4/32                ether4                       10.10.5.2      
 5  L 20                                                            10.255.255.5/32                ether4                       10.10.5.2      
[paninanq@R01.MSK] > mpls forwarding-table print 
Flags: H - hw-offload, L - ldp, V - vpls, T - traffic-eng 
 #    IN-LABEL                        OUT-LABELS                    DESTINATION                    INTERFACE                    NEXTHOP        
 0    expl-null                      
 1  L 16                                                            10.255.255.2/32                ether2                       10.10.7.1      
 2  L 17                              20                            10.255.255.3/32                ether3                       10.10.6.2      
 3  L 18                              16                            10.255.255.7/32                ether3                       10.10.6.2      
 4  L 19                              17                            10.255.255.6/32                ether3                       10.10.6.2      
 5  L 20                                                            10.255.255.5/32                ether3                       10.10.6.2      
[paninanq@R01.MSK] > tool traceroute 10.255.255.6
 # ADDRESS                          LOSS SENT    LAST     AVG    BEST   WORST STD-DEV STATUS                                                   
 1 10.10.6.2                          0%   20   1.1ms     1.2     0.9     1.7     0.2 <MPLS:L=17,E=0>                                          
 2 10.10.4.2                          0%   20   0.9ms     0.8     0.6     1.1     0.1 <MPLS:L=16,E=0>                                          
 3 10.255.255.6                       0%   20   0.6ms     0.6     0.4       1     0.1        
```

Работает EoMPLS:

```
[paninanq@R01.NY] > interface vpls monitor SGIPC   
       remote-label: 21
        local-label: 21
      remote-status: 
  transport-nexthop: 10.10.4.1
     imposed-labels: 19,21

[paninanq@R01.SPB] > interface vpls monitor SGIPC 
       remote-label: 21
        local-label: 21
      remote-status: 
          transport: 10.255.255.7/32
  transport-nexthop: 10.10.1.2
     imposed-labels: 17,21
```

Ну и между ПК есть связь
```
paninanq@paninanq-BOM-WXX9:~/sem-5/2025_2026-introduction_in_routing-k3323-panina_a_s/lab3$ docker exec -it clab-lab3-PC1 sh
/ # ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
665: eth0@if666: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue state UP 
    link/ether 02:42:ac:0a:00:02 brd ff:ff:ff:ff:ff:ff
    inet 172.10.0.2/24 brd 172.10.0.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::42:acff:fe0a:2/64 scope link 
       valid_lft forever preferred_lft forever
682: eth1@if681: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 9500 qdisc noqueue state UP 
    link/ether aa:c1:ab:95:41:5e brd ff:ff:ff:ff:ff:ff
    inet 192.168.28.100/24 scope global eth1
       valid_lft forever preferred_lft forever
    inet6 fe80::a8c1:abff:fe95:415e/64 scope link 
       valid_lft forever preferred_lft forever
/ # exit
paninanq@paninanq-BOM-WXX9:~/sem-5/2025_2026-introduction_in_routing-k3323-panina_a_s/lab3$ docker exec -it clab-lab3-SGI-PRISM sh
/ # ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
671: eth0@if672: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue state UP 
    link/ether 02:42:ac:0a:00:03 brd ff:ff:ff:ff:ff:ff
    inet 172.10.0.3/24 brd 172.10.0.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::42:acff:fe0a:3/64 scope link 
       valid_lft forever preferred_lft forever
689: eth1@if690: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 9500 qdisc noqueue state UP 
    link/ether aa:c1:ab:93:4c:ee brd ff:ff:ff:ff:ff:ff
    inet 192.168.14.100/24 scope global eth1
       valid_lft forever preferred_lft forever
    inet6 fe80::a8c1:abff:fe93:4cee/64 scope link 
       valid_lft forever preferred_lft forever
/ # ping 192.168.28.100
PING 192.168.28.100 (192.168.28.100): 56 data bytes
64 bytes from 192.168.28.100: seq=0 ttl=60 time=1.342 ms
64 bytes from 192.168.28.100: seq=1 ttl=60 time=1.579 ms
64 bytes from 192.168.28.100: seq=2 ttl=60 time=1.379 ms
64 bytes from 192.168.28.100: seq=3 ttl=60 time=1.556 ms
64 bytes from 192.168.28.100: seq=4 ttl=60 time=1.580 ms
^C
--- 192.168.28.100 ping statistics ---
5 packets transmitted, 5 packets received, 0% packet loss
round-trip min/avg/max = 1.342/1.487/1.580 ms
/ # 
```

## Заключение
В результате работы была создана сеть связи, поверх которой настроен OSPF, MPLS и EoMPLS.