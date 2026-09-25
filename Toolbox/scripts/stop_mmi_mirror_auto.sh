#!/bin/sh
# Stop the V2.3 lifecycle supervisor and ensure BaseVideo is withdrawn.
# The Java-owned CarPlay screen marker is deliberately left untouched; it is a
# statement of actual HMI state, not a supervisor control flag.

export PATH=/proc/boot:/bin:/usr/bin:/usr/sbin:/sbin:/mnt/app/armle/bin:/mnt/app/armle/usr/bin:$PATH

SCRIPTDIR="/eso/hmi/engdefs/scripts/mqb"
PIDFILE="/tmp/mmi-mirror-supervisor.pid"
STOP_HELPER="${SCRIPTDIR}/stop_mmi_mirror_toolbox.sh"

is_live_pid() {
    PID="$1"
    case "${PID}" in ''|*[!0-9]*) return 1 ;; esac
    kill -0 "${PID}" 2>/dev/null
}

RESULT=0
SUP_PID=""
if [ -f "${PIDFILE}" ]; then
    SUP_PID=$(cat "${PIDFILE}" 2>/dev/null || echo "")
fi

if is_live_pid "${SUP_PID}"; then
    echo "Stopping MMI Mirror V2.3 auto lifecycle (PID ${SUP_PID})..."
    kill -TERM "${SUP_PID}" 2>/dev/null || RESULT=1
    WAIT=0
    while is_live_pid "${SUP_PID}" && [ "${WAIT}" -lt 4 ]; do
        sleep 1
        WAIT=$((WAIT + 1))
    done
    if is_live_pid "${SUP_PID}"; then
        echo "WARNING: supervisor did not exit after TERM; sending KILL."
        kill -KILL "${SUP_PID}" 2>/dev/null || RESULT=1
        sleep 1
    fi
else
    echo "MMI Mirror V2.3 auto lifecycle is not running."
fi
rm -f "${PIDFILE}" 2>/dev/null || true

# A killed supervisor may not have reached its trap; independently withdraw
# BaseVideo using the same V2.2-proven Stop helper.
if [ -f "${STOP_HELPER}" ]; then
    /bin/sh "${STOP_HELPER}" || RESULT=1
else
    echo "ERROR: BaseVideo stop helper is missing: ${STOP_HELPER}"
    RESULT=1
fi

if [ "${RESULT}" -eq 0 ]; then
    echo "MMI Mirror V2.3 auto lifecycle stopped; BaseVideo withdrawn."
else
    echo "WARNING: V2.3 auto-lifecycle stop completed with one or more errors."
fi
exit "${RESULT}"
