#!/usr/bin/with-contenv bash
# shellcheck shell=bash
# ==============================================================================
# Home Assistant Community Add-on: Base Images
# Displays a simple add-on banner on startup
# ==============================================================================
. /etc/s6-overlay/scripts/hassio_compat.sh
if supervisor_ping; then
    log_info '-----------------------------------------------------------'
    log_info " Add-on: $(addon_name)"
    log_info " $(addon_description)"
    log_info '-----------------------------------------------------------'

    log_info " Add-on version: $(addon_version)"
    if var_true "$(addon_update_available)"; then
        log_warn ' There is an update available for this add-on!'
        log_warn " Latest add-on version: $(addon_version_latest)"
        log_warn ' Please consider upgrading as soon as possible.'
    else
        log_info ' You are running the latest version of this add-on.'
    fi

    log_info " System: $(uname -s) ($(uname -m))"
    log_info " Home Assistant Core: ${HOMEASSISTANT_INFO:-unknown}"
    log_info " Home Assistant Supervisor: ${HASS_SUPERVISOR_INFO:-unknown}"

    log_info '-----------------------------------------------------------'
    log_info ' Please, share the above information when looking for help'
    log_info ' or support in, e.g., GitHub, forums or the Discord chat.'
    log_info '-----------------------------------------------------------'
fi
