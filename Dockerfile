ARG ARCH_PREFIX
FROM homeassistant/${ARCH_PREFIX}-addon-otbr:latest AS base
FROM base

COPY rootfs /