#!/usr/bin/with-contenv bash
# shellcheck shell=bash
# ==============================================================================
# Log how to reach this border router from Home Assistant
# ==============================================================================
# There is no Supervisor to push discovery to, so rather than claiming a
# discovery message was sent, print what the user has to enter by hand under
# Settings -> Devices & Services -> Add Integration -> OpenThread Border Router.
. /etc/s6-overlay/scripts/hassio_compat.sh

# `sed -n 1p` rather than `head -n 1`: head closes the pipe after one line, which
# makes otbr-agent's CLI daemon log "Failed to write CLI output: Broken pipe".
log_info "RCP firmware: $(ot-ctl rcp version | sed -n 1p)"

if var_has_value "$(addon_port 8081)"; then
    log_info "Add to Home Assistant with URL: http://$(addon_hostname):8081 (or the host's IP)"
else
    log_info "REST API is bound to $(addon_ip_address) only. Set OTBR_REST_PORT=8081 to reach it from Home Assistant."
fi
