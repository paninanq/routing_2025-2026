/interface vlan
add name=vlan10_ether3 vlan-id=10 interface=ether3
add name=vlan10_ether4 vlan-id=10 interface=ether4
/interface bridge
add name=bridge_vlan10
/interface bridge port
add interface=vlan10_ether3 bridge=bridge_vlan10
add interface=vlan10_ether4 bridge=bridge_vlan10
/ip dhcp-client
add disabled=no interface=bridge_vlan10
/user add name=paninanq password=paninanq group=full
/system identity set name=SW2
