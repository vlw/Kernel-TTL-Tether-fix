#!/system/bin/sh
MODDIR=${0%/*}
touch "$MODDIR/remove"
if [ -f "$MODDIR/state/pids" ]; then
  read -r main rest < "$MODDIR/state/pids"
  kill "$main" 2>/dev/null
fi
sh "$MODDIR/cleanup.sh"
