# v1.3

## RU

- IPv6: исходящий Hop Limit фиксируется на 64; входящий HL=1 увеличивается до 2 до маршрутизации.
- Link-local unicast и multicast IPv6 не изменяются для сохранения Neighbor Discovery и других локальных управляющих пакетов.
- BPF-обход снимается для IPv4 и IPv6; оба семейства правил и фильтров восстанавливаются при отключении.
- Обработка остаётся событийной, без периодического опроса и NFQUEUE.

## EN

- IPv6: outgoing Hop Limit is set to 64; incoming HL=1 is increased to 2 before forwarding.
- IPv6 link-local unicast and multicast remain unchanged to preserve Neighbor Discovery and local control traffic.
- Removes IPv4 and IPv6 BPF bypass; restores both rule families and filters on disabling.
- Handling remains event-driven, without periodic polling or NFQUEUE.

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
