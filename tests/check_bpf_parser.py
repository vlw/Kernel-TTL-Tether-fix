"""Exercise the actual shell parser with dual-stack and unrelated filter fixtures."""
from pathlib import Path
import subprocess
import tempfile

source = Path('service.sh').read_text()
start = source.index('    for family in 4 6; do')
end = source.index('\n  done\n  reconciles=', start)
parser = source[start:end]
fixtures = '''filter protocol ipv6 pref 2 bpf chain 0
filter protocol ipv6 pref 2 bpf chain 0 handle 0x1 prog_offload_schedcls_tether_upstream6_ether:[*fsobj] direct-action
filter protocol ip pref 3 bpf chain 0
filter protocol ip pref 3 bpf chain 0 handle 0x1 prog_offload_schedcls_tether_upstream4_ether:[*fsobj] direct-action
filter protocol all pref 49152 bpf chain 0
filter protocol all pref 49152 bpf chain 0 handle 0x1 prog_oplus-netd_schedcls_ingress_data_redirect:[*fsobj]
'''
with tempfile.TemporaryDirectory() as directory:
    body = '''set -eu
MODDIR=$1
iface=wlan2
mkdir -p "$MODDIR/state"
tc() { printf '%s\\n' "$*"; }
filters=$(cat <<'FIXTURE'
''' + fixtures + '\nFIXTURE\n)\n' + parser
    result = subprocess.check_output(['bash', '-c', body, 'parser-test', directory], text=True)
    assert result.splitlines() == [
        'filter del dev wlan2 ingress protocol ip pref 3',
        'filter del dev wlan2 ingress protocol ipv6 pref 2',
    ], result
    records = (Path(directory) / 'state/tc_restore').read_text().splitlines()
    assert len(records) == 2 and all('oplus' not in line for line in records)
print('Dual-stack BPF detection and restore records: OK')
