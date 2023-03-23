#!/bin/sh

_base_path="$(dirname $0)"
_this="$0"

export LOG_FILE="$(pwd)/dockver-compose.log"

. $_base_path/script/function.sh

_COMPOSE_PATH="$_base_path/docker-compose"
_GROUPS="$(find $_COMPOSE_PATH -name "*.yml" -type f -exec basename {} \; | sed "s|.yml||")"

usage() {
    echo "
Usage: /bin/bash $_this [OPTION]...

[OPTION]

    --delete        Delete compose containers.
    --clean         Delete all compose containers and volumes.
    -h, --help      Help. This message

[Group]
$(echo "$_GROUPS" | sed 's|^|  - |')

Examples:
    /bin/sh $_this
    or 
    /bin/sh $_this -g management -g gitlab-runner
"
    if [ ! -z "$1" ];
    then
        exit $1
    fi
}

_select_group=""
_is_delete="0"

while [ "$#" -gt 0 ];
do
	arg="$1"
	arg_value="$2"
	case $arg in
        --delete)
            _is_delete="1"
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

if [ ! -z "$_select_group" ];
then
    _GROUPS="$_select_group"
fi


_docker_bin="$(dirname $(which docker) 2>/dev/null)"
if [ -z "$_docker_bin" ];
then
    error "Not found docker. Docker was not install or not exported 'docker' command"
fi

_compose_cmd="$(which docker-compose)"
if [ -z "$_compose_cmd" ];
then
    _compose_cmd="$_docker_bin/docker-compose"
    info "Required docker compose install. path='$_compose_cmd'"
    curl -SL https://github.com/docker/compose/releases/download/v2.16.0/docker-compose-linux-$_OS_ARCH -o "$_compose_cmd"
    if [ $? -ne 0 ];
    then
        error "Cannot install docker-compose"
    fi
    chmod +x "$_compose_cmd"
fi

if [ "$_is_delete" -eq 0 ];
then
    _env_file="$_COMPOSE_PATH/.env"

    if [ -e "$_env_file" ];
    then
        warn "Exists environment. Will be over-write."
    fi

    echo "# docker-compose environment
    $(get_vault_kv "docker" "data" "-format=yaml" | sed 's/: /=/')
    " | tee "$_env_file" > /dev/null
    if [ $? -ne 0 ];
    then
        error "Cannot generate env file"
    fi

    grep "^[^#]" /etc/resolv.conf | awk '{print "PRIMARY_DNS="$2}' | head -1 | tee -a "$_env_file" > /dev/null

    _docker_socket_path="/var/run"
    if [ ! -z "$XDG_RUNTIME_DIR" ];
    then
        _docker_socket_path="$XDG_RUNTIME_DIR"
    fi

    echo "DOCKER_SOCKET=$_docker_socket_path/docker.sock" | tee -a "$_env_file" > /dev/null

    info "Genereate environment file at '$_env_file'"
fi


docker-compose -f "$_COMPOSE_PATH/docker-compose.yml" -p default up -d