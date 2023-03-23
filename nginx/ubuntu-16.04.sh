#!/bin/sh

. $FUNCTION_SCRIPT

# Nginx configuration
apt-get -y update && apt-get install -y nginx
exec_check $? "Installed nginx from apt" "Cannot install nginx from apt repo"

_nginx_conf_file="$_base_path/nginx/default.conf"
_nginx_target_conf_file="/etc/nginx/sites-available/default"

patch_file "$_nginx_conf_file" "$_nginx_target_conf_file"
info "Replaced nginx default config file."

nginx -s reload
exec_check $? "Nginx reloaded." "Fail nginx reload"