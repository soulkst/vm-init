#!/bin/sh

. $FUNCTION_SCRIPT

APT_REPO="$(get_default "$PKG_REPO" "http://mirror.kakao.com")"
APT_SOURCES="/etc/apt/sources.list"
PRE_PACKAGES="$(get_default "$PRE_PACKAGES" "ca-certificates qemu-guest-agent")"
