#!/usr/bin/with-contenv bash
# Minimal compatibility shim to replace common `bashio` calls
# when running the container standalone (no Home Assistant supervisor).

log_info() { echo "[INFO] $*"; }
log_warn() { echo "[WARN] $*"; }
log_error() { echo "[ERROR] $*" >&2; }

supervisor_ping() { return 0; }

addon_name() { echo "${ADDON_NAME:-OpenThread Border Router (OTBR)}"; }
addon_description() { echo "${ADDON_DESCRIPTION:-OTBR standalone container}"; }
addon_version() { echo "${ADDON_VERSION:-unknown}"; }
addon_update_available() { echo "false"; }
addon_version_latest() { echo "$(addon_version)"; }
addon_hostname() { hostname -f 2>/dev/null || hostname; }
addon_ip_address() { echo "${ADDON_IP_ADDRESS:-127.0.0.1}"; }

addon_port() {
    # Call as: addon_port 8080 -> reads env ADDON_PORT_8080 or OTBR_PORT_8080
    local port="$1" var="ADDON_PORT_${port}" var2="OTBR_PORT_${port}"
    echo "${!var:-${!var2:-}}"
}

var_true() { [ "$1" = "true" ] || [ "$1" = "1" ]; }
var_has_value() { [ -n "$1" ]; }

config_key_to_env() { echo "$1" | tr '[:lower:]' '[:upper:]' | tr '.-' '__'; }
config_get() { local k; k=$(config_key_to_env "$1"); echo "${!k:-}"; }
config_has_value() { [ -n "$(config_get "$1")" ]; }
config_true() { [ "$(config_get "$1")" = "true" ] || [ "$(config_get "$1")" = "1" ]; }
config_exists() {
    local k
    k=$(config_key_to_env "$1")
    [ -n "${!k:-}" ] && return 0 || return 1
}

string_lower() { echo "$1" | tr '[:upper:]' '[:lower:]'; }

exit_nok() { log_error "$*"; exit 1; }

api_supervisor() {
    # Minimal substitute for: bashio::api.supervisor 'GET' '/network/info' ...
    # Return primary network interface name (or empty).
    if [ "$1" = "GET" ] && [ "$2" = "/network/info" ]; then
        ip route show default 2>/dev/null | awk '/default/ {print $5; exit}' || true
        return 0
    fi
    return 1
}

var_json() {
    # Build a simple json object from key value pairs: key val key val ...
    printf '%s' '{'
    local first=1
    while [ $# -gt 0 ]; do
        local key="$1"; shift
        local val="$1"; shift
        if [ "$first" -eq 0 ]; then printf ','; fi
        first=0
        local escaped
        escaped="${val//\\/\\\\}"
        escaped="${escaped//\"/\\\"}"
        printf '"%s":"%s"' "$key" "$escaped"
    done
    printf '%s' '}'
}

discovery_send() { # no-op but report success
    return 0
}

addon_option() { :; }
