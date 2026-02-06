#!/usr/bin/with-contenv bash
# shellcheck shell=bash
# ==============================================================================
# OpenThread Border Router - Standalone Container Banner
# ==============================================================================
. /etc/s6-overlay/scripts/hassio_compat.sh

log_info '-----------------------------------------------------------'
log_info " OpenThread Border Router (OTBR)"
log_info " Standalone container - no supervisor required"
log_info '-----------------------------------------------------------'
log_info " Container: $(addon_hostname)"
log_info " System: $(uname -s) ($(uname -m))"
log_info " Backbone Interface: ${BACKBONE_IF:-auto-detected}"
log_info " Device: ${DEVICE:-/dev/ttyACM0}"
log_info '-----------------------------------------------------------'
log_info ' GitHub: https://github.com/D34DC3N73R/ha-otbr'
log_info '-----------------------------------------------------------'
