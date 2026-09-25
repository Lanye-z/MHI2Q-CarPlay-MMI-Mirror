#!/bin/sh
# Clear only disposable MMI Mirror logs and installer/launcher self-test leftovers.
# Active controller/HMI/BaseVideo/CarPlay/supervisor lifecycle state is retained;
# use the matching Stop action to withdraw ownership/processes instead.

RESULT=0
for f in \
    /tmp/mmi-mirror-display.log \
    /tmp/mmi-mirror-display.log.1 \
    /tmp/mmi-mirror-controller.log \
    /tmp/mmi-mirror-controller.log.1 \
    /tmp/mmi-mirror-supervisor.log \
    /tmp/mmi-mirror-supervisor.log.1 \
    /tmp/mmi-mirror-supervisor-boot.log \
    /tmp/mmi-mirror-install-selftest.log \
    /tmp/mmi-mirror-launcher-selftest-bin.sh \
    /tmp/mmi-mirror-launcher-selftest.log \
    /tmp/mmi-mirror-launcher-selftest.log.1 \
    /tmp/mmi-mirror-launcher-selftest.stdout
do
    if [ -e "$f" ]; then
        rm -f "$f" 2>/dev/null || RESULT=1
    fi
done

if [ "${RESULT}" -eq 0 ]; then
    echo "Temporary MMI Mirror V2.3 logs cleared; runtime/CarPlay lifecycle state preserved."
else
    echo "WARNING: some temporary MMI Mirror V2.3 logs could not be removed."
fi
exit "${RESULT}"
