ARG ARCH_PREFIX
FROM homeassistant/${ARCH_PREFIX}-addon-otbr:latest

COPY rootfs /
