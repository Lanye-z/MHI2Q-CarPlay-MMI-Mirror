#!/bin/sh
# Boot entry for MMI Mirror V2.3 automatic lifecycle.
# Starts only the lightweight supervisor after a bounded boot delay; it does NOT
# start BaseVideo unless Java has published CarPlay MAIN_SCREEN=DEVICE.

export PATH=/proc/boot:/bin:/usr/bin:/usr/sbin:/sbin:/mnt/app/armle/bin:/mnt/app/armle/usr/bin:$PATH

SCRIPTDIR="${MMI_MIRROR_TOOLBOX_SCRIPTDIR:-/eso/hmi/engdefs/scripts/mqb}"
SUPERVISOR="${SCRIPTDIR}/mmi_mirror_supervisor.sh"
LOG="/tmp/mmi-mirror-supervisor.log"
DELAY="${MMI_MIRROR_AUTORUN_DELAY:-15}"

sleep "${DELAY}"

if [ ! -f "${SUPERVISOR}" ]; then
    echo "$(date 2>/dev/null || echo time-unknown) | ERROR autorun supervisor missing: ${SUPERVISOR}" >> "${LOG}" 2>/dev/null || true
    exit 1
fi

exec /bin/sh "${SUPERVISOR}"
