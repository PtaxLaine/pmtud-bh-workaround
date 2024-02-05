#!/usr/bin/bash
set -euo pipefail

WHOIS_EXE="/usr/bin/whois"
ZIP_EXE="/usr/bin/gzip"
GAWK_EXE="/usr/bin/gawk"
IP_EXE="/usr/bin/ip"

CACHE_TTL=$((3600 * 48)) # 48h
CACHE_DIR="/var/cache/pmtubd-workaround"

WHOIS_SERVICE="whois.radb.net"
INDEPENDENT_IP="1.1.1.1" # random public IP

IP_RULE_MAIN_PREF=99
IP_RULE_TARGET_PREF=100


stop() {
    >&2 echo "STOP! $*"
    false
}


# check_dependicies
for exe in $WHOIS_EXE $ZIP_EXE $GAWK_EXE $IP_EXE; do
    [[ ! -f "$exe" ]] && stop "'$exe' not found!"
    true
done;
if [[ ! $($IP_EXE -4 rule list table main pref 32766) ]]; then
    stop "Error: you use unsupported network configuration"
fi;


# parse argv
[[ $# < 2 ]] && stop "Usage: pmtubd-workaround.sh TARGET_ASN TARGET_MTU"
[[ ! "$1" =~ ^AS[0-9]+$ ]] && stop "invalid ASN"
[[ ! "$2" =~ ^[0-9]+$ ]] && stop "invalid MTU"

TARGET_ASN="$1"
TARGET_MTU="$2"
IP_TABLE_NUMBER="10297$(echo "$TARGET_ASN" | $GAWK_EXE 'match($0, /AS([0-9]+)/, a) {print a[1]}')"


# recv subnets
CACHE_FILE="$CACHE_DIR/$TARGET_ASN.inet.dat"
update_cache(){
    mkdir -p $CACHE_DIR
    RESPONSE=$($WHOIS_EXE -h "$WHOIS_SERVICE" -- -i origin "$TARGET_ASN")
    [[ "" != "$(echo "$RESPONSE" | grep "%  No entries found")" ]] && stop "No entries found for $TARGET_ASN"
    ROUTES="$(echo "$RESPONSE" | $GAWK_EXE 'match($0, /route:\s*([0-9./]+)/, a) {print a[1]}')"
    echo "$ROUTES" | "$ZIP_EXE" -c > "$CACHE_FILE"
}

[[ ! -f "$CACHE_FILE" ]] && update_cache

LAST_MOD_TIME=$(date -r "$CACHE_FILE" +%s)
CURRENT_TIME=$(date +%s)
[[ ($(($LAST_MOD_TIME + $CACHE_TTL)) < $CURRENT_TIME) ]] && update_cache

SUBNETS="$("$ZIP_EXE" -d -c "$CACHE_FILE")"


# get default route
DEFAULT_ROUTE=$($IP_EXE -4 route get $INDEPENDENT_IP)
DEFAULT_GW="$(echo "$DEFAULT_ROUTE" | $GAWK_EXE 'match($0, /via\s+([0-9.]+)/, a) {print a[1]}')"
DEFAULT_DEV="$(echo "$DEFAULT_ROUTE" | $GAWK_EXE 'match($0, /dev\s+([a-zA-Z0-9._\-]+)/, a) {print a[1]}')"


# create routing rules
if [[ ! $($IP_EXE -4 rule list pref "$IP_RULE_MAIN_PREF" table main) ]]; then
    $IP_EXE -4 rule add pref "$IP_RULE_MAIN_PREF" table main suppress_prefixlength 0
fi;
if [[ ! $($IP_EXE -4 rule list pref "$IP_RULE_TARGET_PREF" table "$IP_TABLE_NUMBER") ]]; then
    $IP_EXE -4 rule add pref "$IP_RULE_TARGET_PREF" table "$IP_TABLE_NUMBER"
fi;


# fill the routing table with fresh subnets
for subnet in $SUBNETS; do
    $IP_EXE -4 route replace "$subnet" table "$IP_TABLE_NUMBER" dev "$DEFAULT_DEV" via "$DEFAULT_GW" mtu "$TARGET_MTU"
done;


# cleanup the routing table of outdated subnets
ACTIVE_SUBNETS="$($IP_EXE -4 route show table "$IP_TABLE_NUMBER" | $GAWK_EXE 'match($0, /([0-9./]+)/, a) {print a[1]}')"
for active_subnet in $ACTIVE_SUBNETS; do
    if [[ ! $SUBNETS[@] =~ $active_subnet ]]; then
        $IP_EXE -4 route del table "$IP_TABLE_NUMBER" "$active_subnet" || true
    fi;
done;

# cleanup route cache
$IP_EXE -4 route flush cache
