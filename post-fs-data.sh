#!/system/bin/sh
MODDIR=${0%/*}
rmdir "$MODDIR/state/lock" 2>/dev/null
