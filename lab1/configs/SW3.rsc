/interface vlan
add name=vlan20_ether3 vlan-id=20 interface=ether3
add name=vlan20_ether4 vlan-id=20 interface=ether4
/interface bridge
add name=bridge_vlan20
/interface bridge port
add interface=vlan20_ether3 bridge=bridge_vlan20
add interface=vlan20_ether4 bridge=bridge_vlan20
/ip dhcp-client
add disabled=no interface=bridge_vlan20
/user add name=paninanq password=paninanq group=full
/system identity set name=SW3