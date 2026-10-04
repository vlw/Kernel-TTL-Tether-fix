"""Extract one release section while keeping CHANGELOG.md as the full history."""
import re


def release_notes(changelog: str, version: str, repository: str) -> str:
    sections = list(re.finditer(r'^# (v\d+\.\d+(?:\.\d+)?)\s*$', changelog, re.MULTILINE))
    matches = [i for i, section in enumerate(sections) if section.group(1) == version]
    if len(matches) != 1:
        raise ValueError(f'Expected exactly one changelog section for {version}')
    index = matches[0]
    start = sections[index].start()
    end = sections[index + 1].start() if index + 1 < len(sections) else len(changelog)
    history = f'https://github.com/{repository}/blob/master/CHANGELOG.md'
    return changelog[start:end].strip() + f'\n\n---\n\n[Полная история изменений / Full changelog]({history})\n'
