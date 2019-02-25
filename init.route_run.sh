 #! /system/bin/sh
 
 file="/data/info.xml"
 
 function update_udhcpd_conf()
{
 local start_ip_value=`getvalue "start_ip_value"`
 local end_ip_value=`getvalue "end_ip_value"`
 local opt_dns_value=`getvalue "opt_dns_value"`
 local option_subnet_value=`getvalue "option_subnet_value"`
 local opt_router_value=`getvalue "opt_router_value"`
 
 echo "# dhcpcd configuration for Android Wi-Fi interface\n
# See dhcpcd.conf(5) for details.\n
#\n
# Disable solicitation of IPv6 Router Advertisements\n
#noipv6rs\n
#\n
#interface wlan0\n
# dhcpcd-run-hooks uses these options.\n
#option subnet_mask, routers, domain_name_servers, interface_mtu\n
#\n" > /data/udhcpd.conf
echo "start $start_ip_value\n
end $end_ip_value\n
interface eth0\n
opt dns $opt_dns_value\n
option subnet $option_subnet_value\n
opt router $opt_router_value\n
#option dns 223.6.6.6 223.5.5.5\n
option domain local\n
option lease 86\n
#static_lease 00:60:08:11:ce:4e 192.168.1.100\n
#static_lease 00:60:08:11:ce:38 192.168.1.110" >> /data/udhcpd.conf
 
}
 
 function getNode()
{
	local ret_value="NULL"
#	echo "getNode"
#	echo `netcfg`
	for node in `netcfg`
	do
		#echo "$node"
		if [ "$node"x = "usb0"x ];then
			ret_value="$node"
			#echo "$ret_value"
			break
		fi
		if [ "$node"x = "ppp0"x ];then
			ret_value="$node"
			#echo "$ret_value"
			break
		fi
	done
	echo $ret_value
}
 
 function getvalue()
{
	ret1=`cat $file | grep $1`
	ret2=`echo ${ret1#*>}`
	ret3=`echo ${ret2%<*}`
	echo $ret3
}
 
 function start_4g()
{
	local dest=`getNode`
	echo $dest
	
	while [ "$dest"x = "NULL"x ];do
		sleep 1
		dest=`getNode`
	done
	
	local eth0_ip=`getvalue "eth0_ip_value"`
	echo $eth0_ip
	local tmp=`echo ${eth0_ip#*.}`
	echo $tmp
	
	echo "start_4g"
	echo 0 > /proc/sys/net/ipv4/ip_forward
	
	iptables -t nat -A natctrl_nat_POSTROUTING -o $dest -j MASQUERADE
	iptables  -A natctrl_FORWARD -i $dest -o eth0 -m state --state ESTABLISHED,RELATED -g natctrl_tether_counters
	iptables  -A natctrl_FORWARD -i eth0 -o $dest -m state --state INVALID -j DROP
	iptables  -A natctrl_FORWARD -i eth0 -o $dest -g natctrl_tether_counters
	iptables  -A natctrl_tether_counters -i eth0 -o $dest -j RETURN
	iptables  -A natctrl_tether_counters -i $dest -o eth0 -j RETURN
	iptables  -D natctrl_FORWARD -j DROP
	iptables  -A natctrl_FORWARD -j DROP
	
#	ip route add 192.168.1.0/24 dev eth0 table local_network proto static scope link
	ip route add "$tmp.0/24" dev eth0
	#echo "$tmp.0/24"
	echo 1 > /proc/sys/net/ipv4/ip_forward
	
	ifconfig eth0 $eth0_ip up
	#ifconfig eth0 192.168.1.112 up
}

 echo "update udhcpd.conf"
 update_udhcpd_conf
 dev_on=`getprop  dev.bootcomplete`
 echo $dev_on
 while [ -z "$dev_on" ]; do
    echo $dev_on
    dev_on=`getprop  dev.bootcomplete`
	sleep 1
 done
 echo "start 4g route"
 start_4g
 echo "start udhcpd"
 stop rout-ndj
 sleep 1
 start rout-ndj
