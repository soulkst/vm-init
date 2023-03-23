#!/bin/sh

. $FUNCTION_SCRIPT
. "$(get_basepath $0)/ubuntu-base.sh"

# Change apt repo
sed -i "/^#/! s|http://.*/ |$APT_REPO/ubuntu/ |g" $APT_SOURCES
exec_check $? "Default apt repo change to '$APT_REPO'" "Fail apt-repo change to '$APT_REPO'"

apt-get -y update && sudo apt-get install -y $PRE_PACKAGES
exec_check $? "Installed pakcages '$PRE_PACKAGES''" "Fail install packages. command = 'apt-get install -y $PRE_PACKAGES'"