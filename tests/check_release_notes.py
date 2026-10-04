"""Verify isolation of first, middle and last releases and missing sections."""
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
from release_notes import release_notes

history = '# v1.4\n\nnewest\n\n# v1.3\n\nmiddle\n\n# v1.2\n\noldest\n'
for version, expected in [('v1.4', 'newest'), ('v1.3', 'middle'), ('v1.2', 'oldest')]:
    notes = release_notes(history, version, 'vlw/Kernel-TTL-Tether-fix')
    assert expected in notes
    for other in ['newest', 'middle', 'oldest']:
        assert (other in notes) == (other == expected)
    assert notes.count('# v') == 1
    assert '/blob/master/CHANGELOG.md' in notes
for invalid in [history.replace('# v1.4', '# v1.5'), history + '\n# v1.4\nDuplicate']:
    try:
        release_notes(invalid, 'v1.4', 'owner/repo')
    except ValueError:
        pass
    else:
        raise AssertionError('Missing/duplicate versions must fail')
print('Release section isolation and validation: OK')
