#!/bin/sh
# V2.3 wrapper: remove automatic lifecycle state before invoking the proven V2.2
# runtime/JAR/RGI recovery transaction. No V2.2 recovery logic is duplicated here.

SCRIPTDIR="/eso/hmi/engdefs/scripts/mqb"
STOP_AUTO="${SCRIPTDIR}/stop_mmi_mirror_auto.sh"
DISABLE_AUTORUN="${SCRIPTDIR}/disable_mmi_mirror_autorun.sh"
BASE_UNINSTALL="${SCRIPTDIR}/uninstall_mmi_mirror.sh"

if [ -f "${STOP_AUTO}" ]; then
    /bin/sh "${STOP_AUTO}" || {
        echo "ERROR: Could not stop V2.3 auto lifecycle; uninstall aborted."
        exit 1
    }
fi

if [ -f "${DISABLE_AUTORUN}" ]; then
    /bin/sh "${DISABLE_AUTORUN}" || {
        echo "ERROR: Could not disable V2.3 boot autorun; uninstall aborted."
        exit 1
    }
fi

if [ ! -f "${BASE_UNINSTALL}" ]; then
    echo "ERROR: Base MMI Mirror uninstaller is missing: ${BASE_UNINSTALL}"
    exit 1
fi

exec /bin/sh "${BASE_UNINSTALL}"
