#!/usr/bin/with-contenv bash
# shellcheck shell=bash
# ==============================================================================
# Select the OTBR build to run
# ==============================================================================

. /etc/s6-overlay/scripts/hassio_compat.sh

declare otbr_prefix

# config_true 'beta' reads the BETA environment variable.
# Set BETA=1 or BETA=true to run the pre-release build instead of the stable one.
if config_true 'beta'; then
    log_info "Beta mode enabled."
    otbr_prefix="/opt/otbr-beta"
else
    log_info "Stable mode enabled."
    otbr_prefix="/opt/otbr-stable"
fi

if [ ! -f "${otbr_prefix}/sbin/otbr-agent" ]; then
    exit_nok "No otbr-agent in ${otbr_prefix}. The base image layout changed; this image needs updating."
fi

ln -sf "${otbr_prefix}/sbin/otbr-agent" /usr/sbin/otbr-agent
ln -sf "${otbr_prefix}/sbin/otbr-web" /usr/sbin/otbr-web
ln -sf "${otbr_prefix}/sbin/ot-ctl" /usr/sbin/ot-ctl

# ==============================================================================
# Disable OTBR Web if necessary ports are not exposed
# ==============================================================================

# Web UI requires port 8080 to be set
if var_has_value "$(addon_port 8080)"; then
    log_info "Web UI port is exposed, starting otbr-web."
else
    rm -f /etc/s6-overlay/s6-rc.d/user/contents.d/otbr-web
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
