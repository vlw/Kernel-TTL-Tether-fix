#!/system/bin/sh
MODDIR=${0%/*}
for tool in /system/bin/iptables /system/bin/ip6tables; do
for chain in PREROUTING POSTROUTING; do
  target=KTTL_IN
  [ "$chain" = POSTROUTING ] && target=KTTL_OUT
  while $tool -w 2 -t mangle -C "$chain" -j "$target" 2>/dev/null; do
    $tool -w 2 -t mangle -D "$chain" -j "$target"
  done
  $tool -w 2 -t mangle -F "$target" 2>/dev/null
  $tool -w 2 -t mangle -X "$target" 2>/dev/null
done
done
if [ -f "$MODDIR/state/tc_restore" ]; then
  while read -r iface prog protocol pref; do
    [ -e "/sys/class/net/$iface" ] || continue
    /system/bin/tc filter show dev "$iface" ingress 2>/dev/null | grep -q "$prog" && continue
    # Older versions stored only interface and program (IPv4).
    protocol=${protocol:-ip}; pref=${pref:-3}
    pinned="/sys/fs/bpf/tethering/$prog"
    [ -e "$pinned" ] || pinned="/sys/fs/bpf/$prog"
    [ -e "$pinned" ] && /system/bin/tc filter add dev "$iface" ingress protocol "$protocol" pref "$pref" handle 1 bpf da pinned "$pinned" 2>/dev/null
  done < "$MODDIR/state/tc_restore"
fi
if [ -f "$MODDIR/state/offload_original" ]; then
  value=$(cat "$MODDIR/state/offload_original")
  if [ "$value" = null ]; then settings delete global tether_offload_disabled >/dev/null 2>&1; else settings put global tether_offload_disabled "$value" >/dev/null 2>&1; fi
fi
