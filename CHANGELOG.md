# v1.2

## RU

- Добавлена сборка и публикация релизов через GitHub Actions.
- ZIP получает GitHub build provenance attestation и SHA-256.
- Добавлены обновления и список изменений в менеджере KernelSU.
- Служба явно выходит из BusyBox standalone mode при запуске через KSU, чтобы использовать проверенные Android shell, ip и tc.
- Сохранены обработка событий без опроса, исходящий TTL=64 и входящий TTL=1 → 2.

## EN

- Added GitHub Actions release builds and publishing.
- ZIP artifacts receive GitHub build provenance attestations and SHA-256 checksums.
- Added KernelSU manager updates and changelog support.
- The service explicitly leaves BusyBox standalone mode when started by KSU to use the verified Android shell, ip and tc.
- Preserved event-driven handling without polling, outgoing TTL=64 and incoming TTL=1 → 2.
