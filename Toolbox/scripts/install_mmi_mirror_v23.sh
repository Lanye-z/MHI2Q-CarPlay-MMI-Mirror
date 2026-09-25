#!/bin/sh
# V2.3 install gate.
#
# The underlying V2.2 installer transaction is intentionally reused unchanged.
# This wrapper prevents a development branch from installing the old V2.2
# Unified JAR before the V2.3 Java artifact has been rebuilt and explicitly
# promoted with an exact artifact marker.

export PATH=/proc/boot:/bin:/usr/bin:/usr/sbin:/sbin:/mnt/app/media/gracenote/bin:/mnt/app/armle/bin:/mnt/app/armle/usr/bin:$PATH

SCRIPTDIR="/eso/hmi/engdefs/scripts/mqb"
. "${SCRIPTDIR}/util_info.sh"
. "${SCRIPTDIR}/util_mountsd.sh"

if [ -z "${VOLUME:-}" ]; then
    echo "ERROR: No SD-card found"
    exit 1
fi

APP_SOURCE="${VOLUME}/Toolbox/apps/mmi-mirror"
READY_MARKER="${APP_SOURCE}/V2.3-ARTIFACT-READY"
JAR_SOURCE="${APP_SOURCE}/carplay_hook-unified.jar"
BASE_INSTALLER="${SCRIPTDIR}/install_mmi_mirror.sh"

if [ ! -f "${READY_MARKER}" ]; then
    echo "ERROR: V2.3 Unified JAR has not been rebuilt/promoted yet."
    echo "Missing release marker: ${READY_MARKER}"
    echo "This guard intentionally prevents installing the inherited V2.2 JAR as V2.3."
    exit 1
fi

EXPECTED_SIZE=$(sed -n 's/^UnifiedJarSize=//p' "${READY_MARKER}" 2>/dev/null | head -n 1)
EXPECTED_CKSUM=$(sed -n 's/^UnifiedJarCksum=//p' "${READY_MARKER}" 2>/dev/null | head -n 1)
case "${EXPECTED_SIZE}" in
    ''|*[!0-9]*)
        echo "ERROR: Invalid UnifiedJarSize in ${READY_MARKER}"
        exit 1
        ;;
esac
case "${EXPECTED_CKSUM}" in
    ''|*[!0-9]*)
        echo "ERROR: Invalid UnifiedJarCksum in ${READY_MARKER}"
        exit 1
        ;;
esac

if [ ! -s "${JAR_SOURCE}" ]; then
    echo "ERROR: V2.3 Unified JAR is missing: ${JAR_SOURCE}"
    exit 1
fi

ACTUAL_SIZE=$(wc -c < "${JAR_SOURCE}" 2>/dev/null || echo 0)
set -- ${ACTUAL_SIZE}; ACTUAL_SIZE="${1:-0}"
if [ "${ACTUAL_SIZE}" != "${EXPECTED_SIZE}" ]; then
    echo "ERROR: V2.3 Unified JAR size mismatch: expected ${EXPECTED_SIZE}, got ${ACTUAL_SIZE}"
    exit 1
fi

if ! command -v cksum >/dev/null 2>&1; then
    echo "ERROR: cksum is required for the V2.3 release gate"
    exit 1
fi
ACTUAL_CKSUM=$(cksum "${JAR_SOURCE}" 2>/dev/null | awk '{print $1}')
if [ "${ACTUAL_CKSUM}" != "${EXPECTED_CKSUM}" ]; then
    echo "ERROR: V2.3 Unified JAR checksum mismatch: expected ${EXPECTED_CKSUM}, got ${ACTUAL_CKSUM}"
    exit 1
fi

if [ ! -f "${BASE_INSTALLER}" ]; then
    echo "ERROR: Base V2.2 transaction installer is missing: ${BASE_INSTALLER}"
    exit 1
fi

echo "V2.3 artifact gate passed: ${ACTUAL_SIZE} bytes, cksum ${ACTUAL_CKSUM}."
echo "Delegating to the unchanged V2.2 runtime/JAR/RGI transaction installer..."
exec /bin/sh "${BASE_INSTALLER}"
