#!/bin/sh
# Remove only the marked MMI Mirror V2.3 autorun block from /etc/boot/startup.sh.
# Does not alter any unrelated boot entries. Current supervisor state is unchanged;
# use 'Stop V2.3 Auto Lifecycle' separately when desired.

export PATH=/proc/boot:/bin:/usr/bin:/usr/sbin:/sbin:/mnt/app/media/gracenote/bin:/mnt/app/armle/bin:/mnt/app/armle/usr/bin:$PATH

SCRIPTDIR="/eso/hmi/engdefs/scripts/mqb"
. "${SCRIPTDIR}/util_info.sh"
. "${SCRIPTDIR}/util_mountsd.sh"

if [ -z "${VOLUME:-}" ]; then
    echo "ERROR: No SD-card found"
    exit 1
fi

STARTUP="/etc/boot/startup.sh"
BEGIN_MARK="# MMI MIRROR V2.3 AUTORUN BEGIN"
END_MARK="# MMI MIRROR V2.3 AUTORUN END"
BACKUPFOLDER="${VOLUME}/Backup/${VERSION}/MMIMirror"
BACKUP="${BACKUPFOLDER}/startup.sh.before-v2.3-autorun"
FILTERED="/tmp/mmi-mirror-startup-v23.filtered"
TARGET_TMP="${STARTUP}.mmi-v23.tmp"

if [ ! -f "${STARTUP}" ]; then
    echo "ERROR: ${STARTUP} not found"
    exit 1
fi

BEGIN_COUNT=$(grep -c "^${BEGIN_MARK}$" "${STARTUP}" 2>/dev/null || echo 0)
END_COUNT=$(grep -c "^${END_MARK}$" "${STARTUP}" 2>/dev/null || echo 0)
set -- ${BEGIN_COUNT}; BEGIN_COUNT="${1:-0}"
set -- ${END_COUNT}; END_COUNT="${1:-0}"

if [ "${BEGIN_COUNT}" -eq 0 ] && [ "${END_COUNT}" -eq 0 ]; then
    echo "MMI Mirror V2.3 autorun block is already absent."
    exit 0
fi
if [ "${BEGIN_COUNT}" -ne 1 ] || [ "${END_COUNT}" -ne 1 ]; then
    echo "ERROR: malformed V2.3 autorun markers; refusing to modify ${STARTUP}."
    exit 1
fi

mkdir -p "${BACKUPFOLDER}" || exit 1
if [ ! -f "${BACKUP}" ]; then
    cp "${STARTUP}" "${BACKUP}" || {
        echo "ERROR: Could not back up current ${STARTUP}"
        exit 1
    }
    chmod 644 "${BACKUP}" 2>/dev/null || true
fi

rm -f "${FILTERED}" "${TARGET_TMP}" 2>/dev/null || true
awk '
    /^# MMI MIRROR V2.3 AUTORUN BEGIN$/ { skip=1; next }
    /^# MMI MIRROR V2.3 AUTORUN END$/   { skip=0; next }
    !skip { print }
' "${STARTUP}" > "${FILTERED}" || {
    rm -f "${FILTERED}" 2>/dev/null || true
    echo "ERROR: Could not filter V2.3 autorun block"
    exit 1
}

if grep -q '^# MMI MIRROR V2.3 AUTORUN BEGIN$' "${FILTERED}" || \
   grep -q '^# MMI MIRROR V2.3 AUTORUN END$' "${FILTERED}"; then
    rm -f "${FILTERED}" 2>/dev/null || true
    echo "ERROR: Autorun filter verification failed"
    exit 1
fi

mount -uw /mnt/app 2>/dev/null || true
mount -uw /mnt/system 2>/dev/null || true
if ! cp "${FILTERED}" "${TARGET_TMP}"; then
    rm -f "${FILTERED}" "${TARGET_TMP}" 2>/dev/null || true
    mount -ur /mnt/app 2>/dev/null || true
    mount -ur /mnt/system 2>/dev/null || true
    echo "ERROR: Could not stage filtered startup file"
    exit 1
fi
chmod 755 "${TARGET_TMP}" 2>/dev/null || true
if ! mv "${TARGET_TMP}" "${STARTUP}"; then
    rm -f "${FILTERED}" "${TARGET_TMP}" 2>/dev/null || true
    mount -ur /mnt/app 2>/dev/null || true
    mount -ur /mnt/system 2>/dev/null || true
    echo "ERROR: Could not activate filtered startup file"
    exit 1
fi
chmod 755 "${STARTUP}" 2>/dev/null || true
rm -f "${FILTERED}" 2>/dev/null || true
sync 2>/dev/null || true
mount -ur /mnt/app 2>/dev/null || true
mount -ur /mnt/system 2>/dev/null || true

if grep -q '^# MMI MIRROR V2.3 AUTORUN BEGIN$' "${STARTUP}"; then
    echo "ERROR: V2.3 autorun block is still present"
    exit 1
fi

echo "MMI Mirror V2.3 autorun disabled."
echo "No unrelated startup.sh content was intentionally changed."
echo "Current supervisor, if running, is unchanged; use 'Stop V2.3 Auto Lifecycle' to stop it now."
exit 0
