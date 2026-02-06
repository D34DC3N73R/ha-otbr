#!/usr/bin/with-contenv bash
# shellcheck shell=bash
# ==============================================================================
# Select OTBR version and enable mDNSResponder for stable mode
# ==============================================================================

. /etc/s6-overlay/scripts/hassio_compat.sh

# Check if the new multi-build structure exists (HA OTBR 2.16.0+)
# Verify both directories exist AND the binaries are present
if [ -d "/opt/otbr-beta" ] && [ -d "/opt/otbr-stable" ] && [ -f "/opt/otbr-stable/sbin/otbr-agent" ]; then
    # config_true 'beta' reads the BETA environment variable (converted from lowercase)
    # Set BETA=1 or BETA=true to enable beta mode
    if config_true 'beta'; then
        log_info "Beta mode enabled, using OpenThread built-in mDNS."

        ln -sf "/opt/otbr-beta/sbin/otbr-agent" /usr/sbin/otbr-agent
        ln -sf "/opt/otbr-beta/sbin/otbr-web" /usr/sbin/otbr-web
        ln -sf "/opt/otbr-beta/sbin/ot-ctl" /usr/sbin/ot-ctl

        # Disable mDNSResponder as beta uses OpenThread's built-in mDNS
        rm -f /etc/s6-overlay/s6-rc.d/user/contents.d/mdns
        rm -f /etc/s6-overlay/s6-rc.d/otbr-agent/dependencies.d/mdns
    else
        log_info "Stable mode (default), using stable binaries with mDNSResponder."

        ln -sf "/opt/otbr-stable/sbin/otbr-agent" /usr/sbin/otbr-agent
        ln -sf "/opt/otbr-stable/sbin/otbr-web" /usr/sbin/otbr-web
        ln -sf "/opt/otbr-stable/sbin/ot-ctl" /usr/sbin/ot-ctl
        ln -sf "/opt/otbr-stable/sbin/mdnsd" /usr/sbin/mdnsd

        # Enable mDNSResponder for stable mode (if mdnsd exists)
        if [ -f "/opt/otbr-stable/sbin/mdnsd" ]; then
            touch /etc/s6-overlay/s6-rc.d/user/contents.d/mdns
            touch /etc/s6-overlay/s6-rc.d/otbr-agent/dependencies.d/mdns
        else
            log_warn "mdnsd not found - disabling mDNS (service discovery may be limited)."
            rm -f /etc/s6-overlay/s6-rc.d/user/contents.d/mdns
            rm -f /etc/s6-overlay/s6-rc.d/otbr-agent/dependencies.d/mdns
        fi
    fi
else
    log_info "Using legacy base image (pre-2.16.0), binaries already in place."
    
    # Ensure mDNS is enabled for legacy images if mdnsd exists
    if [ -f "/usr/sbin/mdnsd" ]; then
        touch /etc/s6-overlay/s6-rc.d/user/contents.d/mdns
        touch /etc/s6-overlay/s6-rc.d/otbr-agent/dependencies.d/mdns
    else
        log_warn "mdnsd not found - disabling mDNS (service discovery may be limited)."
        rm -f /etc/s6-overlay/s6-rc.d/user/contents.d/mdns
        rm -f /etc/s6-overlay/s6-rc.d/otbr-agent/dependencies.d/mdns
    fi
    
    if config_true 'beta'; then
        log_warn "Beta mode requested but base image doesn't support it. Using stable mode."
    fi
fi

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
