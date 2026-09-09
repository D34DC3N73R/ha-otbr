#!/usr/bin/with-contenv bash
# shellcheck shell=bash
# ==============================================================================
# Configure OTBR depending on add-on settings
# ==============================================================================

. /etc/s6-overlay/scripts/hassio_compat.sh

log_info "Enabling TREL."
ot-ctl trel enable

if config_true 'nat64'; then
    log_info "Enabling NAT64."
    ot-ctl nat64 enable
    ot-ctl dns server upstream enable
fi

# OpenThread's built-in mDNS replaced mDNSResponder in HA OTBR 3.0.0.
# `hostname` is the host's under `network_mode: host`, so this name is stable
# across recreates unless a custom `hostname:` is set in the compose file.
mdns_localhostname="$(hostname)-otbr"
log_info "Setting OpenThread mDNS local hostname to ${mdns_localhostname}."
ot-ctl mdns localhostname "${mdns_localhostname}"
ot-ctl mdns enable

# To avoid asymmetric link quality the TX power from the controller should not
# exceed that of what other Thread routers devices typically use.
ot-ctl txpower 6
