#!/usr/bin/env python3
"""Build a reproducible module ZIP and version-specific KSU update metadata."""
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import zipfile

root = Path(__file__).resolve().parent.parent
props = dict(line.split('=', 1) for line in (root / 'module.prop').read_text().splitlines() if '=' in line)
version = props['version']
assert re.fullmatch(r'v\d+\.\d+(?:\.\d+)?', version), 'Invalid version'
assert int(props['versionCode']) > 0
ref = os.environ.get('GITHUB_REF', '')
if ref.startswith('refs/tags/'):
    assert ref.removeprefix('refs/tags/') == version, 'Tag must match module.prop version'
repo = os.environ.get('GITHUB_REPOSITORY', 'vlw/Kernel-TTL-Tether-fix')
base = f'https://github.com/{repo}/releases/download/{version}'
dist = root / 'dist'
dist.mkdir(exist_ok=True)
name = f'kernel-ttl-tether-{version}.zip'
files = ['module.prop', 'customize.sh', 'service.sh', 'cleanup.sh', 'post-fs-data.sh', 'uninstall.sh', 'LICENSE', 'CHANGELOG.md']
with zipfile.ZipFile(dist / name, 'w', zipfile.ZIP_DEFLATED) as archive:
    for filename in sorted(files):
        data = (root / filename).read_bytes()
        assert b'\r\n' not in data, f'CRLF in {filename}'
        info = zipfile.ZipInfo(filename, (2026, 1, 1, 0, 0, 0))
        info.create_system = 3
        info.compress_type = zipfile.ZIP_DEFLATED
        info.external_attr = (stat.S_IFREG | (0o755 if filename.endswith('.sh') else 0o644)) << 16
        archive.writestr(info, data)
checksum = hashlib.sha256((dist / name).read_bytes()).hexdigest()
(dist / 'SHA256SUMS').write_text(f'{checksum}  {name}\n')
(dist / 'changelog.md').write_bytes((root / 'CHANGELOG.md').read_bytes())
(dist / 'update.json').write_text(json.dumps({'version': version, 'versionCode': int(props['versionCode']), 'zipUrl': f'{base}/{name}', 'changelog': f'{base}/changelog.md'}, indent=2) + '\n')
with zipfile.ZipFile(dist / name) as archive:
    assert archive.testzip() is None
    assert set(archive.namelist()) == set(files)
print(dist / name)
