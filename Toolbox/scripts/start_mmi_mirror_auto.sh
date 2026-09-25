#!/bin/sh
# Manually start the V2.3 CarPlay-gated lifecycle supervisor.
# This is the recommended first vehicle-test entry before enabling boot autorun.

export PATH=/proc/boot:/bin:/usr/bin:/usr/sbin:/sbin:/mnt/app/armle/bin:/mnt/app/armle/usr/bin:$PATH

SCRIPTDIR="/eso/hmi/engdefs/scripts/mqb"
SUPERVISOR="${SCRIPTDIR}/mmi_mirror_supervisor.sh"
PIDFILE="/tmp/mmi-mirror-supervisor.pid"
SCREEN_MARKER="/tmp/mmi-mirror-carplay-screen.active"

is_live_pid() {
    PID="$1"
    case "${PID}" in ''|*[!0-9]*) return 1 ;; esac
    kill -0 "${PID}" 2>/dev/null
}

if [ -f "${PIDFILE}" ]; then
    OLD_PID=$(cat "${PIDFILE}" 2>/dev/null || echo "")
    if is_live_pid "${OLD_PID}"; then
        echo "MMI Mirror V2.3 auto lifecycle already running (PID ${OLD_PID})."
        if [ -f "${SCREEN_MARKER}" ]; then
            echo "CarPlay MAIN_SCREEN state: ACTIVE"
        else
            echo "CarPlay MAIN_SCREEN state: INACTIVE"
        fi
        exit 0
    fi
    rm -f "${PIDFILE}" 2>/dev/null || true
fi

if [ ! -f "${SUPERVISOR}" ]; then
    echo "ERROR: V2.3 supervisor is missing: ${SUPERVISOR}"
    exit 1
fi

if command -v nohup >/dev/null 2>&1; then
    nohup /bin/sh "${SUPERVISOR}" >/dev/null 2>&1 &
else
    /bin/sh "${SUPERVISOR}" >/dev/null 2>&1 &
fi

sleep 1
NEW_PID=$(cat "${PIDFILE}" 2>/dev/null || echo "")
if is_live_pid "${NEW_PID}"; then
    echo "MMI Mirror V2.3 auto lifecycle started. Supervisor PID: ${NEW_PID}"
    if [ -f "${SCREEN_MARKER}" ]; then
        echo "CarPlay MAIN_SCREEN is ACTIVE; BaseVideo will be/has been started."
    else
        echo "CarPlay MAIN_SCREEN is INACTIVE; supervisor is idle."
    fi
    echo "Supervisor log: /tmp/mmi-mirror-supervisor.log"
    echo "CarPlay state: /tmp/mmi-mirror-carplay-screen.state"
    exit 0
fi

echo "ERROR: V2.3 supervisor exited during startup."
echo "Inspect /tmp/mmi-mirror-supervisor.log"
exit 1
