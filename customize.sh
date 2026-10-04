SKIPUNZIP=0
ui_print 'IPv4 kernel TTL fix; no NFQUEUE daemon.'
set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/cleanup.sh" 0 0 0755
set_perm "$MODPATH/uninstall.sh" 0 0 0755
