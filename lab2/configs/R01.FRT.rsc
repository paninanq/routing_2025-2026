/ip pool
add name=dhcp-pool ranges=10.20.0.10-10.20.255.254
/ip dhcp-server
add address-pool=dhcp-pool disabled=no interface=ether4 name=dhcp-server
/ip dhcp-server network
add address=10.20.0.0/16 gateway=10.20.0.1
/ip address
add address=192.168.29.1/30 interface=ether2
add address=192.168.30.2/30 interface=ether3
add address=10.20.0.1/16 interface=ether4
/ip route
add distance=1 dst-address=10.10.0.0/16 gateway=192.168.29.2
add distance=1 dst-address=10.30.0.0/16 gateway=192.168.30.1
/user
add name=paninanq password=paninanq group=full
remove admin
/system identity
set name=R01.FRT