#!/system/bin/sh
MODDIR=${0%/*}
for chain in PREROUTING POSTROUTING; do
  target=KTTL_IN
  [ "$chain" = POSTROUTING ] && target=KTTL_OUT
  while iptables -w 2 -t mangle -C "$chain" -j "$target" 2>/dev/null; do
    iptables -w 2 -t mangle -D "$chain" -j "$target"
  done
  iptables -w 2 -t mangle -F "$target" 2>/dev/null
  iptables -w 2 -t mangle -X "$target" 2>/dev/null
done
if [ -f "$MODDIR/state/tc_restore" ]; then
  while read -r iface prog; do
    [ -e "/sys/class/net/$iface" ] || continue
    tc filter show dev "$iface" ingress 2>/dev/null | grep -q "$prog" && continue
    [ -e "/sys/fs/bpf/tethering/$prog" ] && tc filter add dev "$iface" ingress protocol ip pref 3 handle 1 bpf da pinned "/sys/fs/bpf/tethering/$prog" 2>/dev/null
  done < "$MODDIR/state/tc_restore"
fi
if [ -f "$MODDIR/state/offload_original" ]; then
  value=$(cat "$MODDIR/state/offload_original")
  if [ "$value" = null ]; then settings delete global tether_offload_disabled >/dev/null 2>&1; else settings put global tether_offload_disabled "$value" >/dev/null 2>&1; fi
fi
