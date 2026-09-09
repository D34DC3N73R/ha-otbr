#!/usr/bin/env bash
# Self-check for the config shim and the shared helpers built on it.
# Run from anywhere: ./test_otbr_agent_common.sh
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/rootfs/etc/s6-overlay/scripts"

# shellcheck source=./rootfs/etc/s6-overlay/scripts/hassio_compat.sh
. "${root}/hassio_compat.sh"
# otbr-agent-common sources hassio_compat.sh by absolute path, which does not
# exist outside the container; the sourcing above already provided it.
# shellcheck disable=SC1090
eval "$(grep -v '^\. /etc/s6-overlay/scripts/hassio_compat.sh$' "${root}/otbr-agent-common")"

fail() { echo "FAIL: $*"; exit 1; }

# --- config defaults must mirror the add-on's config.yaml `options:` block ----
# An unset variable used to read as empty, which silently disabled the firewall,
# dropped hardware flow control and produced "?uart-baudrate=" in the spinel URL.
env -u FIREWALL bash -c '. '"${root}"'/hassio_compat.sh; config_true firewall' \
    || fail "firewall must default to on"
env -u FLOW_CONTROL bash -c '. '"${root}"'/hassio_compat.sh; config_true flow_control' \
    || fail "flow_control must default to on"
env -u NAT64 bash -c '. '"${root}"'/hassio_compat.sh; config_true nat64' \
    && fail "nat64 must default to off"
env -u BETA bash -c '. '"${root}"'/hassio_compat.sh; config_true beta' \
    && fail "beta must default to off"

got="$(env -u BAUDRATE bash -c '. '"${root}"'/hassio_compat.sh; config_get baudrate')"
[ "${got}" = "460800" ] || fail "baudrate default '${got}', expected 460800"

# An explicitly set value still wins over the default.
FIREWALL=0 config_true firewall && fail "FIREWALL=0 must disable the firewall"
got="$(BAUDRATE=115200 config_get baudrate)"
[ "${got}" = "115200" ] || fail "explicit baudrate ignored, got '${got}'"

# --- truthiness spellings people actually put in a compose file --------------
for v in true 1 yes on TRUE Yes ON; do
    FIREWALL="$v" config_true firewall || fail "'$v' should be true"
done
for v in false 0 no off ""; do
    # "" falls back to the default (on), so test a key that defaults to off
    NAT64="$v" config_true nat64 && fail "'$v' should be false"
done

# --- log level mapping, shared by otbr-agent/run and otbr-web/run ------------
expect() { # expect <OTBR_LOG_LEVEL> <expected int>
    local got
    OTBR_LOG_LEVEL="$1" got="$(otbr_log_level_to_int)"
    [ "${got}" = "$2" ] || fail "'$1' -> '${got}', expected '$2'"
}

expect debug 7
expect info 6
expect notice 5
expect WARNING 4          # case-insensitive
expect error 3
expect critical 2
expect alert 1
expect emergency 0
expect "" 5               # unset falls back to notice

OTBR_LOG_LEVEL=bogus otbr_log_level_to_int > /dev/null \
    && fail "unknown level should return non-zero"

echo "OK"
