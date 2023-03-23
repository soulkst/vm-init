#!/bin/sh

. $FUNCTION_SCRIPT

if [ -z "$(which vault)" ];
then
    curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

    echo "deb \
    [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main\
    " | tee /etc/apt/sources.list.d/hashicorp.list > /dev/null

    apt-get update && apt-get install -y vault
else
    info "Vault command already installed."
fi


_vault_host=""
_vault_secret=""

while [ -z "$_vault_host" ];
do
    read -p "Enter Vault URL (ex: http://vault.server) : " _vault_host
    if [ -z "$_vault_host" ];
    then
        error "Required host url." 0
    fi
done

export VAULT_ADDR="$_vault_host"
export VAULT_SKIP_VERIFY=true

su -p -c "vault login" $TARGET_USER 

if [ $? -ne 0 ];
then
    error "Login fail. Configure skip."
fi

_rc_file="$TARGET_USER_HOME/.bashrc"
_vault_env_name=".vault.env"
_vault_env="$TARGET_USER_HOME/.vault.env"

if [ "$(grep "$_vault_env_name" $_rc_file | wc -l)" -eq 0 ];
then
    echo ". ~/$_vault_env_name" | tee -a $_rc_file
fi

if [ ! -e "$_vault_env" ];
then
    touch "$_vault_env"
    chown $TARGET_USER:$TARGET_USER "$_vault_env"
fi

if [ "$(grep "^export VAULT_ADDR=" $_vault_env | wc -l)" -eq 0 ];
then
    echo "export VAULT_ADDR=$VAULT_ADDR" | tee -a $_vault_env
else
    sed -i "s|export VAULT_ADDR=.*$|export VAULT_ADDR=$VAULT_ADDR|" $_vault_env
fi

if [ "$(grep "^export VAULT_SKIP_VERIFY=" $_vault_env | wc -l)" -eq 0 ];
then
    echo "export VAULT_SKIP_VERIFY=true" | tee -a $_vault_env
else
    sed -i "s|export VAULT_SKIP_VERIFY=.*$|export VAULT_SKIP_VERIFY=true|" $_vault_env
fi

vault -autocomplete-install