#!/bin/sh
# MMI Mirror V2.3 automatic lifecycle supervisor.
#
# Java publishes /tmp/mmi-mirror-carplay-screen.active only while CarPlay owns
# MAIN_SCREEN. This process is the only bridge from that state to the existing
# Start/Stop helpers. It never writes Cluster context.

export PATH=/proc/boot:/bin:/usr/bin:/usr/sbin:/sbin:/mnt/app/armle/bin:/mnt/app/armle/usr/bin:$PATH

DEFAULT_SCRIPTDIR="/eso/hmi/engdefs/scripts/mqb"
SCRIPTDIR="${MMI_MIRROR_TOOLBOX_SCRIPTDIR:-$DEFAULT_SCRIPTDIR}"
if [ ! -f "${SCRIPTDIR}/start_mmi_mirror_toolbox.sh" ]; then
    if [ "$_" = "/bin/on" ]; then BASE="$0"; else BASE="$_"; fi
    CANDIDATE=$( cd -P -- "$(dirname -- "$(command -v -- "$BASE")")" 2>/dev/null && pwd -P )
    if [ -n "${CANDIDATE}" ]; then SCRIPTDIR="${CANDIDATE}"; fi
fi

START_HELPER="${SCRIPTDIR}/start_mmi_mirror_toolbox.sh"
STOP_HELPER="${SCRIPTDIR}/stop_mmi_mirror_toolbox.sh"
SCREEN_MARKER="/tmp/mmi-mirror-carplay-screen.active"
SCREEN_STATE="/tmp/mmi-mirror-carplay-screen.state"
SUPERVISOR_PID="/tmp/mmi-mirror-supervisor.pid"
SUPERVISOR_LOG="/tmp/mmi-mirror-supervisor.log"
SUPERVISOR_LOG_OLD="/tmp/mmi-mirror-supervisor.log.1"
BASEVIDEO_ACTIVE="/tmp/mmi-mirror-active"
POLL_SECONDS="${MMI_MIRROR_AUTO_POLL_SECONDS:-1}"
HELPER_WAIT_SECONDS="${MMI_MIRROR_AUTO_HELPER_WAIT_SECONDS:-60}"
LOG_MAX_BYTES="${MMI_MIRROR_AUTO_LOG_MAX_BYTES:-131072}"

is_live_pid() {
    PID="$1"
    case "${PID}" in
        ''|*[!0-9]*) return 1 ;;
    esac
    kill -0 "${PID}" 2>/dev/null
}

mmi_native_running() {
    if ! command -v pidin >/dev/null 2>&1; then
        # When pidin is unavailable, the existing active marker is the safest
        # non-invasive fallback. Start/Stop helpers still own process handling.
        [ -f "${BASEVIDEO_ACTIVE}" ]
        return
    fi
    pidin ar 2>/dev/null | grep '[m]mi-mirror-display' >/dev/null 2>&1
}

rotate_log_if_needed() {
    [ -f "${SUPERVISOR_LOG}" ] || return 0
    RAW_SIZE=$(wc -c < "${SUPERVISOR_LOG}" 2>/dev/null || echo 0)
    set -- ${RAW_SIZE}
    SIZE="${1:-0}"
    case "${SIZE}" in ''|*[!0-9]*) SIZE=0 ;; esac
    if [ "${SIZE}" -ge "${LOG_MAX_BYTES}" ]; then
        rm -f "${SUPERVISOR_LOG_OLD}" 2>/dev/null || true
        mv "${SUPERVISOR_LOG}" "${SUPERVISOR_LOG_OLD}" 2>/dev/null || true
    fi
}

log() {
    rotate_log_if_needed
    echo "$(date 2>/dev/null || echo time-unknown) | $*" >> "${SUPERVISOR_LOG}" 2>/dev/null || true
}

stop_basevideo() {
    if [ -f "${STOP_HELPER}" ]; then
        /bin/sh "${STOP_HELPER}" >> "${SUPERVISOR_LOG}" 2>&1
        return $?
    fi
    log "ERROR stop helper missing: ${STOP_HELPER}"
    return 1
}

shutdown_supervisor() {
    trap - 1 2 15
    log "supervisor shutdown requested"
    stop_basevideo || log "WARNING BaseVideo stop failed during supervisor shutdown"
    rm -f "${SUPERVISOR_PID}" 2>/dev/null || true
    log "supervisor stopped"
    exit 0
}

trap 'shutdown_supervisor' 1 2 15

if [ -f "${SUPERVISOR_PID}" ]; then
    OLD_PID=$(cat "${SUPERVISOR_PID}" 2>/dev/null || echo "")
    if is_live_pid "${OLD_PID}"; then
        echo "MMI Mirror V2.3 auto lifecycle already running (PID ${OLD_PID})."
        exit 0
    fi
    rm -f "${SUPERVISOR_PID}" 2>/dev/null || true
fi

echo "$$" > "${SUPERVISOR_PID}" 2>/dev/null || {
    echo "ERROR: could not write ${SUPERVISOR_PID}" >&2
    exit 1
}

# Boot may launch this before the Toolbox HMI scripts are completely available.
WAITED=0
while [ ! -f "${START_HELPER}" ] || [ ! -f "${STOP_HELPER}" ]; do
    if [ "${WAITED}" -ge "${HELPER_WAIT_SECONDS}" ]; then
        log "ERROR lifecycle helpers not available after ${WAITED}s; exiting"
        rm -f "${SUPERVISOR_PID}" 2>/dev/null || true
        exit 1
    fi
    sleep 1
    WAITED=$((WAITED + 1))
done

log "===== MMI Mirror V2.3 AUTO LIFECYCLE START ====="
log "screen_marker=${SCREEN_MARKER} state=${SCREEN_STATE} poll=${POLL_SECONDS}s"
log "policy: MAIN_SCREEN DEVICE -> Start; MAINUNIT/session-stop -> Stop; ctx owned by Java"

LAST_WANTED="unknown"
while true; do
    if [ -f "${SCREEN_MARKER}" ]; then WANTED=1; else WANTED=0; fi

    if [ "${WANTED}" != "${LAST_WANTED}" ]; then
        if [ "${WANTED}" = "1" ]; then
            log "CarPlay MAIN_SCREEN active -> BaseVideo requested"
        else
            log "CarPlay MAIN_SCREEN inactive -> BaseVideo withdrawn"
        fi
    fi

    if [ "${WANTED}" = "1" ]; then
        if ! mmi_native_running; then
            log "starting MMI Mirror BaseVideo"
            if /bin/sh "${START_HELPER}" >> "${SUPERVISOR_LOG}" 2>&1; then
                log "start helper completed"
            else
                log "WARNING start helper failed; retrying after backoff"
                LAST_WANTED="${WANTED}"
                sleep 3
                continue
            fi
        fi
    else
        if [ "${LAST_WANTED}" != "0" ] || mmi_native_running || [ -f "${BASEVIDEO_ACTIVE}" ]; then
            log "stopping MMI Mirror BaseVideo"
            if stop_basevideo; then
                log "stop helper completed"
            else
                log "WARNING stop helper failed; will retry"
            fi
        fi
    fi

    LAST_WANTED="${WANTED}"
    sleep "${POLL_SECONDS}"
done
