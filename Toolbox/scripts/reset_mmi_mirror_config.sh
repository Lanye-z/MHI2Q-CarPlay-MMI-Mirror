#!/bin/sh
# Reset MMI Mirror V2.4 custom display configuration to built-in defaults.
# This removes only /mnt/app/root/mmi-mirror/config.local.

export PATH=/proc/boot:/bin:/usr/bin:/usr/sbin:/sbin:/mnt/app/armle/bin:/mnt/app/armle/usr/bin:$PATH

TARGET_DIR="/mnt/app/root/mmi-mirror"
TARGET="${TARGET_DIR}/config.local"
TARGET_TMP="${TARGET}.new"

if [ ! -d "${TARGET_DIR}" ] || [ ! -x "${TARGET_DIR}/mmi-mirror-display" ]; then
    echo "ERROR: MMI Mirror runtime is not installed in ${TARGET_DIR}."
    echo "Run 'Install/Update MMI Mirror V2.4' first."
    exit 1
fi

if [ ! -f "${TARGET}" ]; then
    rm -f "${TARGET_TMP}" 2>/dev/null || true
    echo "MMI Mirror custom display config is already absent."
    echo "Built-in/default V2.4 profile values will be used on the next BaseVideo start."
    exit 0
fi

mount -uw /mnt/app 2>/dev/null || {
    echo "ERROR: Could not remount /mnt/app writable"
    exit 1
}

rm -f "${TARGET}" "${TARGET_TMP}" 2>/dev/null || {
    mount -ur /mnt/app 2>/dev/null || true
    echo "ERROR: Could not remove ${TARGET}"
    exit 1
}

sync 2>/dev/null || true
mount -ur /mnt/app 2>/dev/null || true

if [ -f "${TARGET}" ]; then
    echo "ERROR: Reset verification failed; ${TARGET} still exists."
    exit 1
fi

echo "MMI Mirror V2.4 custom display config reset to defaults."
echo "Removed: ${TARGET}"
echo "Built-in/default profile values take effect the next time BaseVideo starts."
exit 0
