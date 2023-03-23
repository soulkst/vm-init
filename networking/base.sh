
. $FUNCTION_SCRIPT

NET_STATIC_IP_NIC="$NET_STATIC_IP_NIC"
NET_STATIC_IP="$NET_STATIC_IP"
NET_STATIC_IP_GW="$NET_STATIC_IP_GW"
NET_STATIC_IP_NETMASK="$(get_default "$NET_STATIC_IP_NETMASK" "255.255.255.0")"
NET_STATIC_DNS_SERVERS="$NET_STATIC_DNS_SERVERS"
# support mode 'gw', 'google', 'kt'
NET_DNS_STRATEGY="$(get_default "$NET_DNS_STRATEGY" "gw")"

if [ -z "$NET_STATIC_IP_NIC" ];
then
    NET_STATIC_IP_NIC="$(ip -br -c link show | grep -v "lo" | awk '{print $1}')"
    if [ "$(echo "$NET_STATIC_IP_NIC" | wc -l)" -ne 1 ];
    then
        error "If set static ip, required set specific network interface using 'NET_STATIC_IP_NIC' environment."
    fi
fi

if [ -z "$NET_STATIC_IP_GW" ];
then
    NET_STATIC_IP_GW="$(route -n | grep UG | grep "$NET_STATIC_IP_NIC" | awk '{print $2}')"
    info "Network gateway is '$NET_STATIC_IP_GW'"
fi

_CURRENT_IP="$(ip -4 -o address show $NET_STATIC_IP_NIC | awk '{print $4}' |  sed "s|/.*$||")"

if [ -z "$NET_STATIC_DNS_SERVERS" ];
then
    case $NET_DNS_STRATEGY in
        gw)
            NET_STATIC_DNS_SERVERS="$NET_STATIC_IP_GW"
        ;;
        google)
            NET_STATIC_DNS_SERVERS="8.8.8.8"
        ;;
        kt)
            NET_STATIC_DNS_SERVERS="168.126.63.1 168.126.63.2"
        ;;
        *)
            error "Unknown dns server strategy. current = '$NET_DNS_STRATEGY'"
        ;;
    esac
    warn "Not dns-server setted. Will be set (starategy = $NET_DNS_STRATEGY) : '$NET_STATIC_DNS_SERVERS'"
fi
