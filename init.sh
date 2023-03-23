#!/bin/sh

_this="$0"
usage() {
    echo "
Usage: /bin/bash $_this [OPTION]... [FILE]
* All commands required root privilige.

[FILE] - Environement file. If set, Overide all environment variables

[OPTION]

    -i, --ignore [Ininitalize]      Ignore initalize. (multiple)
    -o, --only [Ininitalize]        Set specific initialized  (multiple)
    -ip, --static-ip                Static IP address
    --reboot [value]                Will reboot when all initialize success. If want immediately, using 'now'. (default: '30s')
    -h, --help                      Help. This message

[Environment variables]
    LOG_FILE                    logging file for this script execution. If not set, store current location. (default: $(pwd)/init.log))
    TARGET_USER                 for Non-root required initilized. (default: \$SUDO_USER)

    [ package repository (apt, yum) ]
    PKG_REPO                    Package repository (apt, yum) url. (default: http://mirror.kakao.com)
    PKG_PRE_PACKAGES            Pre install packages by apt or yum. (default: ca-certificates qemu-guest-agent)

    [ network ]
    NET_STATIC_IP_NIC           Network interface. Example: $(ip -br -4 link show | grep -v lo | head -1 | awk '{print $1}') (default: first item)
    NET_STATIC_IP               Static IP address
    NET_STATIC_IP_GW            IP Gateway address
    NET_STATIC_IP_NETMASK       subnet mask (default: 255.255.255.0)
    NET_DNS_STRATEGY            DNS name server reserved strategy (default: gw)
                                : Values. kt, google, gw 
    NET_STATIC_DNS_SERVERS      DNS name servers. Related 'NET_DNS_STRATEGY' envrionment.
                                : Defaults
                                    - gw: \$STATIC_IP_GW
                                    - kt: 168.126.63.1 168.126.63.2
                                    - google: 8.8.8.8

[Ininitalize]
    - repo      Package repository(apt, yum, ...) Initialize
    - net       Networking Initialize (aka. static-ip)
    - docker    Docker install
    - nginx     Install nginx and configure reverse proxy
    - valut     Install vault and intialize client
    - ssh       SSH configuration

Examples:
    sudo /bin/sh $_this -ip 192.168.53.202
    or 
    sudo /bin/sh $_this -ip 192.168.53.202 .envronment
"
    if [ ! -z "$1" ];
    then
        exit $1
    fi
}

is_init() {
    local pkg="#""$1"
    echo "$_INIT_TARGETS" | grep "$pkg" | wc -l
}

export ABSOLUTE_PATH="$(realpath $(dirname "$0"))"
export BASE_SCRIPT_PATH="$ABSOLUTE_PATH/script"
export FUNCTION_SCRIPT="$BASE_SCRIPT_PATH/function.sh"

. $FUNCTION_SCRIPT

export _BASE_PATH="$(get_basepath $0)"
export LOG_FILE="$(get_default "$LOG_FILE" "$(pwd)/init.log")"

# Default variables
export TARGET_USER="$(get_default "$TARGET_USER" "$SUDO_USER")"
export TARGET_USER_HOME="$(eval echo "~$TARGET_USER")"
export TMP_PATH="$(pwd)/.init-tmp"

mkdir -p $TMP_PATH

info "Start script at '$(date)'"

if [ "$(whoami)" != "root" ];
then
    error "Required root permission." 0
    usage 1
fi

_REBOOT_TIME=""
_INIT_TARGETS="#repo #net #docker #nginx #vault #ssh"

_selected_init=""
_ignore_init=""

while [ "$#" -gt 0 ];
do
	arg="$1"
	arg_value="$2"
	case $arg in
        -i|--ignore)
            _ignore_init="$_ignore_init ""#""$arg_value"
            shift
            ;;
        -o|--only)
            _selected_init="$_selected_init ""#""$arg_value"
            shift
            ;;
		-ip|--static-ip)
			export NET_STATIC_IP=$arg_value
            shift
			;;
        --reboot)
            _REBOOT_TIME="30s"
            if [ ! -z "$arg_value" ];
            then
                _REBOOT_TIME="$arg_value"
                shift
            fi
            ;;
		-h|--help)
			usage 0
			;;
		*)
			error "Invalid arguement '$arg'"
			usage 1
			;;
	esac
	shift
done

if [ ! -z "$_selected_init" ] && [ ! -z "$_ignore_init" ];
then
    error "Illegal option. Cannot use '-i(--ignore)' with '-o(--only)' at same time."
fi

if [ ! -z "$_selected_init" ];
then
    _INIT_TARGETS="$_selected_init"
fi

if [ ! -z "$_ignore_init" ];
then
    for _ignore_init_item in $_ignore_init
    do
        _INIT_TARGETS="$(echo "$_INIT_TARGETS" | sed "s|$_ignore_init_item||")"
    done
fi

info "Os Info : name = '$_OS_NAME', version = '$_OS_VERSION', arch = '$_OS_ARCH'"
if [ ! -z "$_IGNORES" ];
then
    info "Ignore packages: $_IGNORES"
fi

# Network initialize
if [ $(is_init "net") -eq 1 ];
then
    _networking_script="$_BASE_PATH/networking/$_OS_NAME-$_OS_VERSION.sh"
    if [ ! -e "$_networking_script" ];
    then
        error "Fail networking initialize. Unsupport os. os = '$_OS_NAME', version = '$_OS_VERSION'"
    fi
    /bin/sh "$_networking_script"
    exec_check $? "Networking initialize complete." "Networking initialize fail."
else
    info "Ignore network initialize"
fi

# Package repository initialize
if [ $(is_init "repo") -eq 1 ];
then
    _repo_script="$_BASE_PATH/repo-package/$_OS_NAME-$_OS_VERSION.sh"
    if [ ! -e "$_repo_script" ];
    then
        error "Fail package repo initialize. Unsupport os. os = '$_OS_NAME', version = '$_OS_VERSION'"
    fi
    /bin/sh "$_repo_script"
    exec_check $? "Package repo initialize complete." "Package repo initialize fail."
else
    info "Ignore Package repository initialize"
fi

# Nginx initialize
if [ $(is_init "nginx") -eq 1 ];
then
    _nginx_script="$_BASE_PATH/nginx/$_OS_NAME-$_OS_VERSION.sh"
    if [ ! -e "$_nginx_script" ];
    then
        error "Cannot install 'nginx'. Unsupport os. os = '$_OS_NAME', version = '$_OS_VERSION'"
    fi
    /bin/sh "$_nginx_script"
    exec_check $? "Nginx installed complete." "Fail Nginx install."
else
    info "Ignore Nginx initialize"
fi

# Vault initialize
if [ $(is_init "vault") -eq 1 ];
then
    _valut_script="$_BASE_PATH/vault/$_OS_NAME-$_OS_VERSION.sh"
    if [ ! -e "$_valut_script" ];
    then
        error "Cannot install 'vault'. Unsupport os. os = '$_OS_NAME', version = '$_OS_VERSION'"
    fi
    /bin/sh "$_valut_script"
    exec_check $? "Vault installed complete." "Fail Vault install."
else
    info "Ignore Vault initialize"
fi

if [ ! -z $(which vault) ] && [ -z "$VAULT_ADDR" ];
then
    . $TARGET_USER_HOME/.vault.env
fi

# SSH
if [ $(is_init "ssh") -eq 1 ];
then
    _ssh_script="$_BASE_PATH/ssh/$_OS_NAME-$_OS_VERSION.sh"
    if [ ! -e "$_ssh_script" ];
    then
        error "Cannot configure 'ssh'. Unsupport os. os = '$_OS_NAME', version = '$_OS_VERSION'"
    fi
    /bin/sh "$_ssh_script"
    exec_check $? "SSH configure complete." "Fail SSH configure."
else
    info "Ignore SSH configure"
fi

rm -rf "$TMP_PATH"

if [ ! -z "$_REBOOT_TIME" ];
then
    info "REBOOT: $_REBOOT_TIME"
    if [ "$_REBOOT_TIME" != "now" ];
    then
        warn "Will be reeboot after $_REBOOT_TIME. If want stop, Input 'Ctrl + c' interrupt."
        sleep $_REBOOT_TIME
    else
        warn "Reboot..."
    fi
    sudo reboot now
fi