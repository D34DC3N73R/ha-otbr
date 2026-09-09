#!/usr/bin/with-contenv bash
# Minimal compatibility shim to replace common `bashio` calls
# when running the container standalone (no Home Assistant supervisor).

log_info() { echo "[INFO] $*"; }
log_warn() { echo "[WARN] $*"; }
log_error() { echo "[ERROR] $*" >&2; }

string_lower() { echo "$1" | tr '[:upper:]' '[:lower:]'; }

exit_nok() { log_error "$*"; exit 1; }

addon_hostname() { hostname -f 2>/dev/null || hostname; }
addon_ip_address() { echo "${ADDON_IP_ADDRESS:-127.0.0.1}"; }

addon_port() {
    # Call as: addon_port 8080 -> reads env ADDON_PORT_8080, OTBR_PORT_8080, or OTBR_WEB_PORT
    local port="$1" var="ADDON_PORT_${port}" var2="OTBR_PORT_${port}" var3
    if [ "$port" = "8080" ]; then var3="OTBR_WEB_PORT"; elif [ "$port" = "8081" ]; then var3="OTBR_REST_PORT"; fi
    echo "${!var:-${!var2:-${!var3:-}}}"
}

var_has_value() { [ -n "$1" ]; }

# Defaults mirroring the add-on's config.yaml `options:` block. Without them an
# unset variable reads as empty, which silently turns off things the add-on has
# on by default (flow control, firewall) or builds a malformed spinel URL.
config_default() {
    case "$1" in
        baudrate)       echo "460800" ;;
        flow_control)   echo "true" ;;
        otbr_log_level) echo "notice" ;;
        firewall)       echo "true" ;;
        nat64)          echo "false" ;;
        beta)           echo "false" ;;
    esac
}

config_key_to_env() { echo "$1" | tr '[:lower:]' '[:upper:]' | tr '.-' '__'; }
config_get() {
    local k
    k=$(config_key_to_env "$1")
    echo "${!k:-$(config_default "$1")}"
}
config_has_value() { [ -n "$(config_get "$1")" ]; }
config_true() {
    # Accept the spellings people actually put in a compose file, so a stray
    # `FIREWALL: "yes"` cannot quietly disable the firewall.
    case "$(string_lower "$(config_get "$1")")" in
        true | 1 | yes | on) return 0 ;;
        *) return 1 ;;
    esac
}

primary_interface() {
    # Substitute for asking the Supervisor which interface is primary.
    ip route show default 2>/dev/null | awk '/default/ {print $5; exit}'
}
