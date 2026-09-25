#!/bin/sh
# Collect MMI Mirror V2.3 runtime + Java ownership + CarPlay lifecycle/RGI diagnostics to SD-card.

export PATH=/proc/boot:/bin:/usr/bin:/usr/sbin:/sbin:/mnt/app/media/gracenote/bin:/mnt/app/armle/bin:/mnt/app/armle/usr/bin:$PATH
export IPL_CONFIG_DIR="${IPL_CONFIG_DIR:-/etc/eso/production}"

if [ "$_" = "/bin/on" ]; then BASE="$0"; else BASE="$_"; fi
SCRIPTDIR=$( cd -P -- "$(dirname -- "$(command -v -- "$BASE")")" && pwd -P )

. "${SCRIPTDIR}/util_info.sh"
. "${SCRIPTDIR}/util_mountsd.sh"
if [ -z "${VOLUME:-}" ]; then
    echo "No SD-card found, quitting"
    exit 1
fi

STAMP=$(date +%Y%m%d_%H%M%S 2>/dev/null || echo "latest")
case "${STAMP}" in
    ''|*' '*|*':'*) STAMP="latest" ;;
esac

BASEFOLDER="${VOLUME}/Backup/${VERSION}/MMIMirror/RuntimeLogs"
LOGFOLDER="${BASEFOLDER}/${STAMP}"
RUNTIME="/mnt/app/root/mmi-mirror"
JAR_TARGET="/mnt/app/eso/hmi/lsd/jars/carplay_hook.jar"
RESULT=0

mkdir -p "${LOGFOLDER}" || { echo "ERROR: Could not create ${LOGFOLDER}"; exit 1; }

copy_optional() {
    SOURCE="$1"
    FILENAME="$2"
    TARGET="${LOGFOLDER}/${FILENAME}"
    TMP="${TARGET}.tmp"
    if [ ! -f "${SOURCE}" ]; then
        echo "Optional file not present: ${SOURCE}"
        return 0
    fi
    rm -f "${TMP}" 2>/dev/null || true
    if cp "${SOURCE}" "${TMP}" && chmod 644 "${TMP}" && mv "${TMP}" "${TARGET}"; then
        echo "Saved ${SOURCE} -> ${TARGET}"
        return 0
    fi
    rm -f "${TMP}" 2>/dev/null || true
    echo "ERROR: Could not save ${SOURCE}"
    RESULT=1
    return 1
}

echo "===== Collecting MMI Mirror V2.3 diagnostics ====="
echo "Firmware: ${VERSION}"
echo "FAZIT: ${FAZIT}"
echo "Destination: ${LOGFOLDER}"

# V2.2 BaseVideo + Java ownership diagnostics retained unchanged in V2.3.
copy_optional "/tmp/mmi-mirror-display.log.1" "mmi-mirror-display.log.1"
copy_optional "/tmp/mmi-mirror-display.log" "mmi-mirror-display.log"
copy_optional "/tmp/mmi-mirror-controller.log" "mmi-mirror-controller.log"
copy_optional "/tmp/mmi-mirror-controller.started" "mmi-mirror-controller.started"
copy_optional "/tmp/mmi-mirror-hmi.state" "mmi-mirror-hmi.state"
copy_optional "/tmp/mmi-mirror-active" "mmi-mirror-active"
copy_optional "/tmp/mmi-mirror-basevideo.ready" "mmi-mirror-basevideo.ready"

# Unified CarPlay Java / RGI logs. Different revisions use slightly different
# logging layouts, so collect every known current/rotated file opportunistically.
copy_optional "/tmp/carplay_java.log.1" "carplay_java.log.1"
copy_optional "/tmp/carplay_java.log" "carplay_java.log"
copy_optional "/tmp/carplay_hook.log.1" "carplay_hook.log.1"
copy_optional "/tmp/carplay_hook.log" "carplay_hook.log"
copy_optional "/tmp/maneuver_render.log.1" "maneuver_render.log.1"
copy_optional "/tmp/maneuver_render.log" "maneuver_render.log"

# V2.3 CarPlay-screen state + supervisor lifecycle diagnostics.
copy_optional "/tmp/mmi-mirror-carplay-screen.active" "mmi-mirror-carplay-screen.active"
copy_optional "/tmp/mmi-mirror-carplay-screen.state" "mmi-mirror-carplay-screen.state"
copy_optional "/tmp/mmi-mirror-supervisor.log.1" "mmi-mirror-supervisor.log.1"
copy_optional "/tmp/mmi-mirror-supervisor.log" "mmi-mirror-supervisor.log"
copy_optional "/tmp/mmi-mirror-supervisor-boot.log" "mmi-mirror-supervisor-boot.log"
copy_optional "/tmp/mmi-mirror-supervisor.pid" "mmi-mirror-supervisor.pid"

copy_optional "${RUNTIME}/INSTALL_INFO.txt" "INSTALL_INFO.txt"
copy_optional "${RUNTIME}/config.local" "config.local"

SYSTEM_TMP="${LOGFOLDER}/system_info.txt.tmp"
{
    echo "===== MMI Mirror V2.3 system info ====="
    date
    echo "Firmware=${VERSION}"
    echo "FAZIT=${FAZIT}"
    echo "Runtime=${RUNTIME}"
    echo "Architecture=JAVA80 ctx80={98,101,102,3}; idle=74; bounce=72; Native context routing removed"
    echo "AutoLifecycle=CarPlay MAIN_SCREEN DEVICE->Start MAINUNIT->Stop"
    echo
    echo "===== Relevant /tmp files ====="
    ls -l /tmp/mmi-mirror* /tmp/carplay* /tmp/maneuver* 2>&1 || true
    echo
    echo "===== Filesystems ====="
    df /tmp /mnt/app 2>&1 || df 2>&1 || true
} > "${SYSTEM_TMP}" 2>&1
chmod 644 "${SYSTEM_TMP}" 2>/dev/null || true
mv "${SYSTEM_TMP}" "${LOGFOLDER}/system_info.txt" 2>/dev/null || RESULT=1

FILES_TMP="${LOGFOLDER}/runtime_files.txt.tmp"
{
    echo "===== Runtime files ====="
    ls -ld "${RUNTIME}" 2>&1 || true
    ls -l "${RUNTIME}" 2>&1 || true
    ls -l "${RUNTIME}/scripts" 2>&1 || true
    echo
    echo "===== Installed carplay_hook.jar ====="
    ls -l "${JAR_TARGET}" 2>&1 || true
    if [ -f "${JAR_TARGET}" ]; then
        echo -n "size="; wc -c < "${JAR_TARGET}" 2>/dev/null || true
        if command -v cksum >/dev/null 2>&1; then echo -n "cksum="; cksum "${JAR_TARGET}" 2>/dev/null || true; fi
    fi
    echo
    echo "===== V2.3 Toolbox lifecycle helpers ====="
    ls -l "${SCRIPTDIR}/mmi_mirror_supervisor.sh" "${SCRIPTDIR}/mmi_mirror_autostart.sh" \
          "${SCRIPTDIR}/start_mmi_mirror_auto.sh" "${SCRIPTDIR}/stop_mmi_mirror_auto.sh" \
          "${SCRIPTDIR}/enable_mmi_mirror_autorun.sh" "${SCRIPTDIR}/disable_mmi_mirror_autorun.sh" 2>&1 || true
} > "${FILES_TMP}" 2>&1
chmod 644 "${FILES_TMP}" 2>/dev/null || true
mv "${FILES_TMP}" "${LOGFOLDER}/runtime_files.txt" 2>/dev/null || RESULT=1

PROC_TMP="${LOGFOLDER}/processes.txt.tmp"
{
    echo "===== Processes containing MMI / CarPlay / HMI / renderer names ====="
    pidin ar 2>&1 | grep -i -E 'mmi|maneuver_render|carplay|lsd|hmi' || true
    echo
    echo "BaseVideo wrapper PID file:"
    cat /tmp/mmi-mirror-stage1.pid 2>/dev/null || echo "not present"
    echo
    echo "V2.3 supervisor PID file:"
    cat /tmp/mmi-mirror-supervisor.pid 2>/dev/null || echo "not present"
} > "${PROC_TMP}" 2>&1
chmod 644 "${PROC_TMP}" 2>/dev/null || true
mv "${PROC_TMP}" "${LOGFOLDER}/processes.txt" 2>/dev/null || RESULT=1

AUTORUN_TMP="${LOGFOLDER}/autorun_state.txt.tmp"
{
    echo "===== /etc/boot/startup.sh V2.3 autorun markers ====="
    if [ -f /etc/boot/startup.sh ]; then
        grep -n 'MMI MIRROR V2.3 AUTORUN' /etc/boot/startup.sh 2>&1 || echo "V2.3 autorun block not present"
    else
        echo "/etc/boot/startup.sh not present"
    fi
} > "${AUTORUN_TMP}" 2>&1
chmod 644 "${AUTORUN_TMP}" 2>/dev/null || true
mv "${AUTORUN_TMP}" "${LOGFOLDER}/autorun_state.txt" 2>/dev/null || RESULT=1

# One-shot display-manager snapshots are diagnostics only; no runtime polling exists.
GS_TMP="${LOGFOLDER}/dmdt_gs.txt.tmp"
/eso/bin/apps/dmdt gs > "${GS_TMP}" 2>&1 || true
chmod 644 "${GS_TMP}" 2>/dev/null || true
mv "${GS_TMP}" "${LOGFOLDER}/dmdt_gs.txt" 2>/dev/null || RESULT=1

GC_TMP="${LOGFOLDER}/dmdt_gc.txt.tmp"
/eso/bin/apps/dmdt gc > "${GC_TMP}" 2>&1 || true
chmod 644 "${GC_TMP}" 2>/dev/null || true
mv "${GC_TMP}" "${LOGFOLDER}/dmdt_gc.txt" 2>/dev/null || RESULT=1

sync || { echo "ERROR: sync failed"; RESULT=1; }

if [ "${RESULT}" -eq 0 ]; then
    echo "MMI Mirror V2.3 diagnostics collected successfully."
else
    echo "MMI Mirror V2.3 diagnostics collection completed with one or more copy errors."
fi
echo "Saved under: Backup/${VERSION}/MMIMirror/RuntimeLogs/${STAMP}"
echo "===== MMI Mirror V2.3 diagnostics collection finished ====="
exit "${RESULT}"
