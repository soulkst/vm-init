get_basepath() {
    echo "$(dirname $1)"
}

get_default() {
    if [ -z "$1" ];
    then
        echo "$2"
        return 0
    fi
    echo "$1"
}

info() {
    echo "--  INFO]    $1" | tee -a $LOG_FILE
}

warn() {
    echo "##  WARN]    $1" | tee -a $LOG_FILE
}

error() {
    echo "!! ERROR]    $1" | tee -a $LOG_FILE 1>&2
    if [ -z "$2" ];
    then
        exit 1
    fi
}

patch_file() {
    local src="$1"
    local target="2"
    local diff_cnt="$(diff -y --suppress-common-lines "$src" "$target" | wc -l)"
    exec_check $? "" "Cannot diff compare file. files = ['$src', '$target']"

    if [ $diff_cnt -ne 0 ];
    then
        local backup_file="$target"".""$(date '+%Y%m%d_%H%M%S')"
        mv "$target" "$backup_file"
        exec_check $? "Origin file '$src' backup to '$target'" "Cannot backup file to '$target'."
    fi
    cp -f "$src" "$target"
    exec_check $? "Patched file. '$target'" "Cannot patch file '$src' to '$target'"
    return 0
}

exec_check() {
    if [ $1 -ne 0 ];
    then
        error "$3" $4
    else
        if [ ! -z "$2" ];
        then
            info "$2"
        fi
    fi
}

get_vault_kv() {
    local _vault_user="$(vault token lookup | grep path | awk -F/ '{print $NF}')"
    if [ $? -ne 0 ];
    then
        echo ""
        return 1
    fi

    vault kv get -mount="$_vault_user/kv" -field="$2" $3 "$1"
    return $?
}

# OS information variables
export _OS_NAME="$(grep "^ID=" /etc/os-release | awk -F= '{print $2}')"
export _OS_VERSION="$(grep "VERSION_ID" /etc/os-release | awk -F= '{print $2}' | sed "s|[^0-9\.]||g")"
export _OS_ARCH="$(uname -m)"