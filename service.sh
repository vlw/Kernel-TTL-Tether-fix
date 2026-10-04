#!/system/bin/sh
# KSU starts scripts in BusyBox standalone mode; use Android ip/tc and shell.
if [ "${ASH_STANDALONE:-0}" = 1 ]; then
  export ASH_STANDALONE=0
  exec /system/bin/sh "$0" "$@"
fi
MODDIR=${0%/*}
PATH=/system/bin:/system/xbin:$PATH
mkdir -p "$MODDIR/state"
mkdir "$MODDIR/state/lock" 2>/dev/null || exit 0
children=""
finish() {
  trap - EXIT TERM INT
  for pid in $children; do kill "$pid" 2>/dev/null; done
  sh "$MODDIR/cleanup.sh"
  rm -f "$MODDIR/state/events" "$MODDIR/state/pids"
  rmdir "$MODDIR/state/lock" 2>/dev/null
}
trap finish EXIT
trap 'exit 0' TERM INT
[ -f "$MODDIR/disable" ] || [ -f "$MODDIR/remove" ] && exit 0
until [ "$(getprop sys.boot_completed)" = 1 ]; do sleep 2; done
if [ ! -f "$MODDIR/state/offload_original" ]; then
  settings get global tether_offload_disabled 2>/dev/null | cat > "$MODDIR/state/offload_original"
fi
settings put global tether_offload_disabled 1 >/dev/null 2>&1
# Wildcard interface rules survive interface recreation and upstream changes.
iptables -w 2 -t mangle -N KTTL_IN 2>/dev/null
iptables -w 2 -t mangle -N KTTL_OUT 2>/dev/null
iptables -w 2 -t mangle -F KTTL_IN
iptables -w 2 -t mangle -F KTTL_OUT
iptables -w 2 -t mangle -A KTTL_IN -i rmnet_data+ -m ttl --ttl-eq 1 -j TTL --ttl-inc 1
iptables -w 2 -t mangle -A KTTL_OUT -o rmnet_data+ -j TTL --ttl-set 64
reconcile() {
  iptables -w 2 -t mangle -C PREROUTING -j KTTL_IN 2>/dev/null || iptables -w 2 -t mangle -I PREROUTING 1 -j KTTL_IN
  iptables -w 2 -t mangle -C POSTROUTING -j KTTL_OUT 2>/dev/null || iptables -w 2 -t mangle -I POSTROUTING 1 -j KTTL_OUT
  # Inspect only tether-capable interfaces; do not touch OEM traffic shapers.
  for path in /sys/class/net/*; do
    iface=${path##*/}
    case "$iface" in wlan*|softap*|ap_br_*|rndis*|usb*|ncm*|bt-pan|rmnet_data*) ;; *) continue ;; esac
    filters=$(tc filter show dev "$iface" ingress 2>/dev/null)
    prog=""
    case "$filters" in *"protocol ip pref 3"*)
      for word in $filters; do
        case "$word" in prog_offload_schedcls_tether_*4_*:*) prog=${word%%:*}; break ;; esac
      done ;;
    esac
    if [ -n "$prog" ]; then
      record="$iface $prog"
      grep -qxF "$record" "$MODDIR/state/tc_restore" 2>/dev/null || printf '%s\n' "$record" >> "$MODDIR/state/tc_restore"
      tc filter del dev "$iface" ingress protocol ip pref 3 2>/dev/null
    fi
  done
  reconciles=$((reconciles + 1))
  printf '%s\n' "$reconciles" > "$MODDIR/state/reconciles"
}
rm -f "$MODDIR/state/events"
mkfifo "$MODDIR/state/events" || exit 1
# Keep FIFO open so individual producers cannot cause EOF or startup deadlock.
exec 3<>"$MODDIR/state/events"
ip -o monitor link >&3 2>/dev/null &
children="$children $!"
tc monitor >&3 2>/dev/null &
children="$children $!"
inotifyd - "$MODDIR:nd" >&3 2>/dev/null &
children="$children $!"
printf '%s\n' "$$ $children" > "$MODDIR/state/pids"
reconciles=0
reconcile
# All processes block on kernel events. No timers, dumpsys or periodic checks.
while IFS= read -r event <&3; do
  case "$event" in
    *"$MODDIR"*disable*|*"$MODDIR"*remove*)
      [ -f "$MODDIR/disable" ] || [ -f "$MODDIR/remove" ] && exit 0 ;;
    *prog_offload_schedcls_tether_*4_*) reconcile ;;
    *": wlan"*|*": softap"*|*": ap_br_"*|*": rndis"*|*": usb"*|*": ncm"*|*": bt-pan"*|*": rmnet_data"*) reconcile ;;
  esac
done
