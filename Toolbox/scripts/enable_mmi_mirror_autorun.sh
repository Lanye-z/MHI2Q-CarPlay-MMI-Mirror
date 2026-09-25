#!/bin/sh
# Enable MMI Mirror V2.3 boot autorun by adding one marked block to
# /etc/boot/startup.sh. This starts only the delayed lifecycle supervisor;
# BaseVideo itself remains gated by CarPlay MAIN_SCREEN ownership.

export PATH=/proc/boot:/bin:/usr/bin:/usr/sbin:/sbin:/mnt/app/media/gracenote/bin:/mnt/app/armle/bin:/mnt/app/armle/usr/bin:$PATH

SCRIPTDIR="/eso/hmi/engdefs/scripts/mqb"
. "${SCRIPTDIR}/util_info.sh"
. "${SCRIPTDIR}/util_mountsd.sh"

if [ -z "${VOLUME:-}" ]; then
    echo "ERROR: No SD-card found"
    exit 1
fi

STARTUP="/etc/boot/startup.sh"
AUTOSTART="${SCRIPTDIR}/mmi_mirror_autostart.sh"
BEGIN_MARK="# MMI MIRROR V2.3 AUTORUN BEGIN"
END_MARK="# MMI MIRROR V2.3 AUTORUN END"
BACKUPFOLDER="${VOLUME}/Backup/${VERSION}/MMIMirror"
BACKUP="${BACKUPFOLDER}/startup.sh.before-v2.3-autorun"
TARGET_TMP="${STARTUP}.mmi-v23.tmp"

if [ ! -f "${STARTUP}" ]; then
    echo "ERROR: ${STARTUP} not found"
    exit 1
fi
if [ ! -f "${AUTOSTART}" ]; then
    echo "ERROR: V2.3 autostart helper is missing: ${AUTOSTART}"
    exit 1
fi

BEGIN_COUNT=$(grep -c "^${BEGIN_MARK}$" "${STARTUP}" 2>/dev/null || echo 0)
END_COUNT=$(grep -c "^${END_MARK}$" "${STARTUP}" 2>/dev/null || echo 0)
set -- ${BEGIN_COUNT}; BEGIN_COUNT="${1:-0}"
set -- ${END_COUNT}; END_COUNT="${1:-0}"

if [ "${BEGIN_COUNT}" -eq 1 ] && [ "${END_COUNT}" -eq 1 ]; then
    echo "MMI Mirror V2.3 autorun block already exists."
    exit 0
fi
if [ "${BEGIN_COUNT}" -ne 0 ] || [ "${END_COUNT}" -ne 0 ]; then
    echo "ERROR: malformed existing V2.3 autorun markers; refusing to modify ${STARTUP}."
    exit 1
fi

mkdir -p "${BACKUPFOLDER}" || exit 1
if [ ! -f "${BACKUP}" ]; then
    cp "${STARTUP}" "${BACKUP}" || {
        echo "ERROR: Could not back up ${STARTUP}"
        exit 1
    }
    chmod 644 "${BACKUP}" 2>/dev/null || true
fi

mount -uw /mnt/app 2>/dev/null || true
mount -uw /mnt/system 2>/dev/null || true
rm -f "${TARGET_TMP}" 2>/dev/null || true

if ! cp "${STARTUP}" "${TARGET_TMP}"; then
    echo "ERROR: Could not stage ${STARTUP}"
    mount -ur /mnt/app 2>/dev/null || true
    mount -ur /mnt/system 2>/dev/null || true
    exit 1
fi

cat >> "${TARGET_TMP}" <<'EOF'

# MMI MIRROR V2.3 AUTORUN BEGIN
if [ -f /eso/hmi/engdefs/scripts/mqb/mmi_mirror_autostart.sh ]; then
    /bin/sh /eso/hmi/engdefs/scripts/mqb/mmi_mirror_autostart.sh >> /tmp/mmi-mirror-supervisor-boot.log 2>&1 &
fi
# MMI MIRROR V2.3 AUTORUN END
EOF
RC=$?

if [ "${RC}" -ne 0 ] || ! grep -q '^# MMI MIRROR V2.3 AUTORUN END$' "${TARGET_TMP}"; then
    rm -f "${TARGET_TMP}" 2>/dev/null || true
    mount -ur /mnt/app 2>/dev/null || true
    mount -ur /mnt/system 2>/dev/null || true
    echo "ERROR: Could not build V2.3 autorun startup file"
    exit 1
fi

chmod 755 "${TARGET_TMP}" 2>/dev/null || true
if ! mv "${TARGET_TMP}" "${STARTUP}"; then
    rm -f "${TARGET_TMP}" 2>/dev/null || true
    mount -ur /mnt/app 2>/dev/null || true
    mount -ur /mnt/system 2>/dev/null || true
    echo "ERROR: Could not activate V2.3 autorun startup file"
    exit 1
fi
chmod 755 "${STARTUP}" 2>/dev/null || true
sync 2>/dev/null || true
mount -ur /mnt/app 2>/dev/null || true
mount -ur /mnt/system 2>/dev/null || true

if ! grep -q '^# MMI MIRROR V2.3 AUTORUN BEGIN$' "${STARTUP}"; then
    echo "ERROR: Autorun verification failed"
    exit 1
fi

echo "MMI Mirror V2.3 autorun enabled."
echo "Only the supervisor starts at boot; MMI BaseVideo starts only while CarPlay owns MAIN_SCREEN."
echo "Original startup backup: Backup/${VERSION}/MMIMirror/startup.sh.before-v2.3-autorun"
echo "Reboot only after manual 'Start V2.3 Auto Lifecycle' tests are confirmed stable."
exit 0
