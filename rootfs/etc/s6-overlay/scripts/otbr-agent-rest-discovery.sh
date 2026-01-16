#!/usr/bin/with-contenv bash
# shellcheck shell=bash
# ==============================================================================
# Send OTBR discovery information to Home Assistant
# ==============================================================================
. /etc/s6-overlay/scripts/hassio_compat.sh
declare config

config=$(var_json \
    host "$(addon_hostname)" \
    port "$(addon_port 8081)" \
    device "$(config_get 'device')" \
    firmware "$(ot-ctl rcp version | head -n 1)" \
)

# Send discovery info
if discovery_send "otbr" "${config}" > /dev/null; then
    log_info "Successfully sent discovery information to Home Assistant."
else
    log_error "Discovery message to Home Assistant failed!"
fi
