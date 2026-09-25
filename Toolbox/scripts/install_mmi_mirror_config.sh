#!/bin/sh
# Install/update an MMI Mirror V2.4 custom display configuration.
# Source: SD/Toolbox/apps/mmi-mirror/config.local
# Target: /mnt/app/root/mmi-mirror/config.local
#
# The runtime launcher sources config.local as shell input, so this installer
# deliberately accepts only known keys with simple numeric/path values.

export PATH=/proc/boot:/bin:/usr/bin:/usr/sbin:/sbin:/mnt/app/armle/bin:/mnt/app/armle/usr/bin:$PATH

SCRIPTDIR="/eso/hmi/engdefs/scripts/mqb"
. "${SCRIPTDIR}/util_info.sh"
. "${SCRIPTDIR}/util_mountsd.sh"

if [ -z "${VOLUME:-}" ]; then
    echo "ERROR: No SD-card found"
    exit 1
fi

SOURCE="${VOLUME}/Toolbox/apps/mmi-mirror/config.local"
TARGET_DIR="/mnt/app/root/mmi-mirror"
TARGET="${TARGET_DIR}/config.local"
TARGET_TMP="${TARGET}.new"
VALIDATED="/tmp/mmi-mirror-config-validated.$$"

cleanup() {
    rm -f "${VALIDATED}" "${TARGET_TMP}" 2>/dev/null || true
}

fail() {
    echo "ERROR: $*"
    cleanup
    mount -ur /mnt/app 2>/dev/null || true
    exit 1
}

if [ ! -f "${SOURCE}" ]; then
    echo "ERROR: Custom display config not found:"
    echo "  Toolbox/apps/mmi-mirror/config.local"
    echo "Copy Toolbox/apps/mmi-mirror/config.local.example to config.local and edit it first."
    exit 1
fi

if [ ! -d "${TARGET_DIR}" ] || [ ! -x "${TARGET_DIR}/mmi-mirror-display" ]; then
    echo "ERROR: MMI Mirror runtime is not installed in ${TARGET_DIR}."
    echo "Run 'Install/Update MMI Mirror V2.4' first."
    exit 1
fi

if ! command -v awk >/dev/null 2>&1; then
    echo "ERROR: awk is required for safe config validation."
    exit 1
fi

# Normalize Windows CRLF before validating/installing. Octal keeps QNX tr portable.
tr -d '\015' < "${SOURCE}" > "${VALIDATED}" || fail "Could not read custom config"
[ -s "${VALIDATED}" ] || fail "Custom config is empty"

awk '
function bad(msg) {
    print "ERROR: config validation failed: " msg > "/dev/stderr"
    failed=1
    exit 1
}
function is_int(v) { return v ~ /^-?[0-9]+$/ }
function is_uint(v) { return v ~ /^[0-9]+$/ }
function is_num(v) { return v ~ /^[0-9]+([.][0-9]+)?$/ }
function is_crop_x(key) { return key ~ /^MMI_(CLASSIC|SPORT)_(FULL|SMALL)_CROP_(LEFT|RIGHT)$/ }
function is_crop_y(key) { return key ~ /^MMI_(CLASSIC|SPORT)_(FULL|SMALL)_CROP_(TOP|BOTTOM)$/ }
BEGIN { assignments=0; failed=0 }
/^[ \t]*$/ { next }
/^[ \t]*#/ { next }
{
    if ($0 !~ /^[A-Z0-9_]+=[^ \t]+$/)
        bad("use KEY=VALUE with no spaces or inline shell syntax: " $0)

    eq=index($0,"=")
    key=substr($0,1,eq-1)
    val=substr($0,eq+1)

    if (val ~ /[`;$|&<>\\(){}]/)
        bad("unsafe characters in " key)

    if (key=="MMI_CLASSIC_FULL_SCALE" || key=="MMI_CLASSIC_SMALL_SCALE" ||
        key=="MMI_SPORT_FULL_SCALE" || key=="MMI_SPORT_SMALL_SCALE" ||
        key=="MMI_CONTENT_SCALE") {
        if (!is_num(val) || (val+0) <= 0 || (val+0) > 4.0)
            bad(key " must be > 0 and <= 4.0")
    } else if (is_crop_x(key)) {
        if (!is_uint(val) || (val+0) > 1023)
            bad(key " must be an integer between 0 and 1023")
        crop[key]=val+0
    } else if (is_crop_y(key)) {
        if (!is_uint(val) || (val+0) > 479)
            bad(key " must be an integer between 0 and 479")
        crop[key]=val+0
    } else if (key=="MMI_CLASSIC_FULL_OFFSET_X" || key=="MMI_CLASSIC_FULL_OFFSET_Y" ||
               key=="MMI_CLASSIC_SMALL_OFFSET_X" || key=="MMI_CLASSIC_SMALL_OFFSET_Y" ||
               key=="MMI_SPORT_FULL_OFFSET_X" || key=="MMI_SPORT_FULL_OFFSET_Y" ||
               key=="MMI_SPORT_SMALL_OFFSET_X" || key=="MMI_SPORT_SMALL_OFFSET_Y" ||
               key=="MMI_OFFSET_X" || key=="MMI_OFFSET_Y") {
        if (!is_int(val) || (val+0) < -8192 || (val+0) > 8192)
            bad(key " must be an integer between -8192 and 8192")
    } else if (key=="MMI_CAPTURE_FPS") {
        if (!is_uint(val) || (val+0) < 1 || (val+0) > 60)
            bad(key " must be between 1 and 60")
    } else if (key=="MMI_CAPTURE_RECOVER_MS") {
        if (!is_uint(val) || (val+0) < 500 || (val+0) > 60000)
            bad(key " must be between 500 and 60000")
    } else if (key=="MMI_HMI_POLL_MS") {
        if (!is_uint(val) || (val+0) < 20 || (val+0) > 5000)
            bad(key " must be between 20 and 5000")
    } else if (key=="MMI_MIRROR_LOG_MAX_BYTES") {
        if (!is_uint(val) || (val+0) < 4096 || (val+0) > 16777216)
            bad(key " must be between 4096 and 16777216")
    } else if (key=="MMI_MIRROR_LOG") {
        if (val !~ /^\/tmp\/[A-Za-z0-9_.-]+$/)
            bad(key " must be a simple /tmp filename")
    } else {
        bad("unknown key " key)
    }
    assignments++
}
END {
    if (failed) exit 1
    if (assignments < 1) bad("no supported assignments found")

    if ((crop["MMI_CLASSIC_FULL_CROP_LEFT"]+0) + (crop["MMI_CLASSIC_FULL_CROP_RIGHT"]+0) >= 1024)
        bad("CLASSIC_FULL left+right crop must be < 1024")
    if ((crop["MMI_CLASSIC_FULL_CROP_TOP"]+0) + (crop["MMI_CLASSIC_FULL_CROP_BOTTOM"]+0) >= 480)
        bad("CLASSIC_FULL top+bottom crop must be < 480")

    if ((crop["MMI_CLASSIC_SMALL_CROP_LEFT"]+0) + (crop["MMI_CLASSIC_SMALL_CROP_RIGHT"]+0) >= 1024)
        bad("CLASSIC_SMALL left+right crop must be < 1024")
    if ((crop["MMI_CLASSIC_SMALL_CROP_TOP"]+0) + (crop["MMI_CLASSIC_SMALL_CROP_BOTTOM"]+0) >= 480)
        bad("CLASSIC_SMALL top+bottom crop must be < 480")

    if ((crop["MMI_SPORT_FULL_CROP_LEFT"]+0) + (crop["MMI_SPORT_FULL_CROP_RIGHT"]+0) >= 1024)
        bad("SPORT_FULL left+right crop must be < 1024")
    if ((crop["MMI_SPORT_FULL_CROP_TOP"]+0) + (crop["MMI_SPORT_FULL_CROP_BOTTOM"]+0) >= 480)
        bad("SPORT_FULL top+bottom crop must be < 480")

    if ((crop["MMI_SPORT_SMALL_CROP_LEFT"]+0) + (crop["MMI_SPORT_SMALL_CROP_RIGHT"]+0) >= 1024)
        bad("SPORT_SMALL left+right crop must be < 1024")
    if ((crop["MMI_SPORT_SMALL_CROP_TOP"]+0) + (crop["MMI_SPORT_SMALL_CROP_BOTTOM"]+0) >= 480)
        bad("SPORT_SMALL top+bottom crop must be < 480")
}
' "${VALIDATED}" || fail "Custom display config was not installed"

mount -uw /mnt/app 2>/dev/null || fail "Could not remount /mnt/app writable"
rm -f "${TARGET_TMP}" 2>/dev/null || true

cp "${VALIDATED}" "${TARGET_TMP}" || fail "Could not stage config.local"
chmod 644 "${TARGET_TMP}" 2>/dev/null || fail "Could not chmod staged config.local"
mv "${TARGET_TMP}" "${TARGET}" || fail "Could not activate config.local"
sync 2>/dev/null || true
mount -ur /mnt/app 2>/dev/null || true
cleanup

echo "MMI Mirror V2.4 custom display config installed."
echo "Source: Toolbox/apps/mmi-mirror/config.local"
echo "Target: ${TARGET}"
echo "The new values take effect the next time BaseVideo starts."
exit 0
