#!/usr/bin/with-contenv bash
# shellcheck shell=bash
# ==============================================================================
# Disable OTBR Web if necessary ports are not exposed
# ==============================================================================

. /etc/s6-overlay/scripts/hassio_compat.sh

if var_has_value "$(addon_port 8080)" \
     && var_has_value "$(addon_port 8081)"; then
    log_info "Web UI and REST API port are exposed, starting otbr-web."
else
    rm /etc/s6-overlay/s6-rc.d/user/contents.d/otbr-web
    log_info "The otbr-web is disabled."
fi

# ==============================================================================
# Enable socat-otbr-tcp service if needed
# ==============================================================================

if config_has_value 'network_device'; then
    touch /etc/s6-overlay/s6-rc.d/user/contents.d/socat-otbr-tcp
    touch /etc/s6-overlay/s6-rc.d/otbr-agent/dependencies.d/socat-otbr-tcp
    log_info "Enabled socat-otbr-tcp."
fi
