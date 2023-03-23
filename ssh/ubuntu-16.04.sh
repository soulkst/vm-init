#/bin/sh

. $FUNCTION_SCRIPT

if [ -z "$(which vault)" ];
then
    info "Not installed vault. Skip"
    exit 0
fi

_ssh_path="$TARGET_USER_HOME/.ssh"
mkdir -p $_ssh_path
if [ $? -ne 0 ];
then
    error "Cannot crate '$_ssh_path' directory."
fi

_pub_key="$(get_vault_kv "ssh" "id_ed25519.pub")"
if [ ! -z "$_pub_key" ];
then
    _authorized_keys="$_ssh_path/authorized_keys"
    if [ ! -e "$_authorized_keys" ];
    then
        touch "$_authorized_keys"
        if [ $? -ne 0 ];
        then
            error "Cannot create 'authorized_keys' file"
        fi
    fi
    _pub_key_only="$(echo "$_pub_key" | awk '{ if (NF>2) NF=NF-1;print $0}')"
    if [ "$(grep "^$_pub_key_only" $_authorized_keys | wc -l)" -eq 0 ];
    then 
        echo "$_pub_key" | tee -a "$_authorized_keys" > /dev/null
        info "Added public key at 'authorized_keys'"
    else
        info "Alread added key."
    fi
fi

chown -R $TARGET_USER:$TARGET_USER "$_ssh_path"