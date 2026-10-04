[RU](README.md) · **EN**

<div align="center">

# Kernel TTL Tether Fix

**Internet tethering with TTL adjustment in the kernel**

KernelSU · Wild Kernel · IPv4 · Version 1.2

</div>

---

A module for the OnePlus 15 running Wild Kernel. It fixes outgoing TTL and
allows incoming packets with TTL=1 to pass through IP forwarding. Packets are
processed by iptables in the kernel, without NFQUEUE. The management service
responds to netlink and inotify events, with no periodic polling.

## How it works

| Direction | Rule | Result |
| --- | --- | --- |
| To the mobile network | `POSTROUTING`, outgoing interface `rmnet_data*` | TTL is set to **64** |
| From the mobile network | `PREROUTING`, incoming interface `rmnet_data*`, TTL=1 | TTL is increased to **2** before forwarding |
| IPv6 | No rules applied | Unchanged |

The outgoing rule also covers the phone's own mobile IPv4 traffic.

To prevent the accelerated path from bypassing these rules, the module disables
hardware tethering offload and removes IPv4 BPF tethering filters. It watches
interface events with `ip monitor link`, filter installation with `tc monitor`,
and module disabling with `inotifyd`. When there are no events, the processes
block while waiting.

## Installation

1. Build the ZIP from the repository root:

   ```sh
   python3 scripts/build.py
   ```

2. Install the archive through the **KernelSU** manager.
3. Keep `nfqttl` and `Unlimited Hotspot` disabled.
4. Reboot the phone.

## Disabling and rollback

Disable the module in KernelSU. The service removes its rules, restores the
original hardware offload setting, and restores the removed BPF filters on
interfaces that still exist. After enabling the module again, reboot the phone
to start the service.

## Resource usage and verification

| Check on the OnePlus 15 | Result |
| --- | --- |
| Outgoing TTL in packet capture | **64** |
| IPv4 BPF filter reinstallation | Handled through an event |
| Interface events | Handled |
| Module disabling | Rules removed; settings and BPF restored |
| Idle without events: 55 seconds, then another 35 seconds | CPU time and context switch counts unchanged |
| Combined RSS of four processes | About **17 MB**, including shared libraries |
| Handling a test BPF installation | About **0.27 seconds of CPU time** |

The handler does not acquire a wakelock. Deep sleep was not measured separately.

### Not yet verified

- Incoming TTL=1 has not yet been observed in live traffic.
- Reboot and an actual tethering restart have not been tested separately.
- Other devices and firmware require verification of interface and BPF program names.

There may be a brief interval between BPF filter installation and event handling.

## Diagnostics

Run in a root shell on the phone:

```sh
# TTL rule counters
iptables -t mangle -L KTTL_OUT -nv
iptables -t mangle -L KTTL_IN -nv

# Event handling count and process IDs
cat /data/adb/modules/ttl_kernel_tether/state/reconciles
cat /data/adb/modules/ttl_kernel_tether/state/pids

# Service log
cat /data/adb/modules/ttl_kernel_tether/state/service.log
```

## Source files

| File | Purpose |
| --- | --- |
| [`service.sh`](service.sh) | TTL rules and event waiting |
| [`cleanup.sh`](cleanup.sh) | Rule cleanup and offload/BPF restoration |
| [`post-fs-data.sh`](post-fs-data.sh) | Remove the stale lock after reboot |
| [`uninstall.sh`](uninstall.sh) | Stop the service and clean up on removal |
| [`customize.sh`](customize.sh) | Installation and file permissions |
| [`module.prop`](module.prop) | Module metadata |

## Author

Vladimir B (vlw)

## License

[MIT](LICENSE) © 2026 Vladimir B (vlw).

## Releases and updates

The [latest release](https://github.com/vlw/Kernel-TTL-Tether-fix/releases/latest) includes the ZIP, `SHA256SUMS`, `update.json`, and a RU/EN changelog. KSU discovers updates through `updateJson` in `module.prop`. Previously installed versions without this field require one manual update.

Builds run when a tag matching `version` in `module.prop` is pushed. For the next release, increase `versionCode`, update `CHANGELOG.md`, and push a signed version tag. The update JSON is published with the completed release and references version-specific assets.

Verify a downloaded ZIP with a current GitHub CLI:

```sh
gh attestation verify kernel-ttl-tether-v1.2.zip --repo vlw/Kernel-TTL-Tether-fix
sha256sum -c SHA256SUMS
```

Attestation proves build provenance, not correctness. The KSU manager does not verify it automatically.
