#!/usr/bin/with-contenv bash
# shellcheck shell=bash
# ==============================================================================
# Disable OTBR Web if necessary ports are not exposed
# ==============================================================================

. /etc/s6-overlay/scripts/hassio_compat.sh

# Web UI requires port 8080 to be set
if var_has_value "$(addon_port 8080)"; then
    log_info "Web UI port is exposed, starting otbr-web."
else
    rm /etc/s6-overlay/s6-rc.d/user/contents.d/otbr-web
    log_info "The otbr-web is disabled."
fi

# REST API is hardcoded to port 8081 (otbr-web and integrations expect this)
# Setting OTBR_REST_PORT controls whether it binds to all interfaces (::) or localhost only
if var_has_value "$(addon_port 8081)"; then
    log_info "REST API will listen on all interfaces (port 8081)."
else
    log_info "REST API will listen on localhost only (port 8081)."
fi

# ==============================================================================
# Enable socat-otbr-tcp service if needed
# ==============================================================================

if config_has_value 'network_device'; then
    touch /etc/s6-overlay/s6-rc.d/user/contents.d/socat-otbr-tcp
    touch /etc/s6-overlay/s6-rc.d/otbr-agent/dependencies.d/socat-otbr-tcp
    log_info "Enabled socat-otbr-tcp."
fi
