#!/bin/sh

. $FUNCTION_SCRIPT
. "$(get_basepath $0)/base.sh"

if [ -z "$NET_STATIC_IP" ];
then
    info "No static ip. Ignored."
    exit 0
fi

info "Current IP: $_CURRENT_IP"

if [ "$NET_STATIC_IP" = "$_CURRENT_IP" ];
then
    info "Already same ip address. Skipped."
    exit 0
fi

DEFAULT_CONF_FILE="/etc/network/interfaces"
sed -i "/^auto $NET_STATIC_IP_NIC/d" $DEFAULT_CONF_FILE
sed -i "/^iface $NET_STATIC_IP_NIC inet dhcp/d" $DEFAULT_CONF_FILE

NETWORK_CONF_FILE="/etc/network/interfaces.d/$NET_STATIC_IP_NIC"
echo "auto $NET_STATIC_IP_NIC
iface $NET_STATIC_IP_NIC inet static
address $NET_STATIC_IP
netmask $NET_STATIC_IP_NETMASK
gateway $NET_STATIC_IP_GW
dns-nameserver $NET_STATIC_DNS_SERVERS" | tee $NETWORK_CONF_FILE > /dev/null

ifdown $NET_STATIC_IP_NIC && ifup $NET_STATIC_IP_NIC
exec_check $? "Reloaded network interface '$NET_STATIC_IP_NIC'" "Fail network interface reload. Recommend reboot"

service networking restart
exec_check $? "Restarted networking service" "Fail networking service restart. Recommend reboot"

info "!!!! Recommend reboot when initialize end."