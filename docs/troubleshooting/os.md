# OS-level Troubleshooting

Kernel / suspend / GPU / storage / firmware issues on this machine (MSI laptop, Meteor Lake iGPU + RTX 5090 Mobile dGPU, Arch + Omarchy + Hyprland). Each entry: what broke, what we know, how to recover, how to prevent.

---

## External monitors dead after wake from suspend

**Symptom**

After resuming from suspend (or "hibernate" that was actually s2idle), USB-C-attached HDMI monitors (via dock) don't come back. Only the laptop's internal panel works. `hyprctl monitors` only shows `eDP-2`.

**What's actually happening**

The monitors are on the **NVIDIA dGPU** via DisplayPort Alt Mode out of the USB-C dock — not on the Intel iGPU.

- `card0` = Intel iGPU → `eDP-2` (laptop panel only).
- `card1` = NVIDIA dGPU → `DP-1`, `DP-2`, `HDMI-A-1`, `eDP-1` (all external paths).

After s2idle resume, the dock's USB hub reconnects but DP Alt Mode does **not** re-negotiate. All `card1-*` connectors report `disconnected` in `/sys/class/drm/`. The kernel doesn't expose a `typec` class on this box (`/sys/class/typec/` doesn't exist), so alt-mode handshake is entirely firmware-controlled — meaning no software path can force it back once it's wedged.

**How to check**

```bash
for c in /sys/class/drm/card1-*/status; do echo "$c: $(cat $c)"; done
hyprctl monitors all
```

If every `card1-*` is `disconnected`, alt mode is gone.

**Recovery (in order of escalation)**

1. **Replug the USB-C cable.** Sometimes re-asserts alt mode. Often doesn't.
2. **Force a DRM connector re-probe** (rarely helps on NVIDIA + alt-mode, but cheap):
   ```bash
   sudo udevadm trigger --action=change --subsystem-match=drm
   sudo sh -c 'for c in /sys/class/drm/card1-DP-1 /sys/class/drm/card1-DP-2 /sys/class/drm/card1-HDMI-A-1; do echo detect > "$c/status"; done'
   ```
   Note: writing `detect` to the debugfs `force` file fails with `Invalid argument` — `force` only accepts `on`/`off`/`unspecified`. Use the regular sysfs `status` file as above.
3. **Soft reboot.** Usually does NOT clear it — the firmware state survives.
4. **Hard power-down.** Unplug charger, hold power button ~40s to drain residual, then boot. This is what actually fixes it.

**Prevention**

Root cause is NVIDIA + USB-C + s2idle. Options:

- **Use real hibernate, not s2idle.** Kernel cmdline already has `resume=/dev/mapper/root resume_offset=…`. BUT: last hibernate attempt failed with `PM: hibernation: Failed to load image, recovering. ... resume failed (-5)`. Likely a stale `resume_offset` — btrfs can relocate the swapfile's physical blocks (CoW, defrag, balance). Re-derive with `filefrag -v <swapfile>` and update the bootloader entry before relying on this.
- **Check if S3 ("deep") sleep is even available:**
  ```bash
  cat /sys/power/mem_sleep
  ```
  If output contains `deep`, switch to it (it survives this issue better than s2idle). If only `[s2idle]` is listed, the firmware doesn't support S3 and you're stuck with s2idle.
- **Disable autosuspend entirely.** Trade battery for not getting wedged: `systemctl mask sleep.target suspend.target` and set `HandleLidSwitch=ignore` in `/etc/systemd/logind.conf.d/`.

**Notes / context from previous incidents**

- The dock's USB hub itself reconnects fine (`05e3:0610` Genesys Logic) — it's only DP Alt Mode that fails.
- The "USB C Video Adaptor" (`25a4:9311`) showing as a USB device is the dock's video controller chip, not a separate DisplayLink adapter. Displays still ride DP Alt Mode on the GPU side.
- `nvidia-suspend.service` and `nvidia-resume.service` are enabled and both fire correctly on suspend/resume — this is not a missing-service problem.
- `NVreg_PreserveVideoMemoryAllocations=1` is defined in BOTH `/etc/modprobe.d/nvidia-power-management.conf` and `/etc/modprobe.d/gsr-nvidia.conf` (the latter from gpu-screen-recorder). Harmless but redundant — drop one.

---

## External USB drive disconnects around suspend

**Symptom**

External drive (`/dev/sda`, EXT4) goes offline shortly before or during suspend. Journal shows:

```
EXT4-fs (sda1): unmounting filesystem ...           # clean unmount, expected
usb 2-2: USB disconnect, device number 2            # drive physically left USB
sd 0:0:0:0: [sda] Synchronize Cache(10) failed:
    Result: hostbyte=DID_ERROR driverbyte=DRIVER_OK # too late, USB already gone
```

**What's actually happening**

The drive's USB connection drops *before* the SCSI layer finishes flushing. Filesystem unmount succeeded cleanly first, so no data loss — the `Synchronize Cache` error is harmless aftermath against an already-gone device.

This is on bus `2-2` (USB SuperSpeed root hub), which is the **same xHCI controller** that handles the USB-C dock. Likely contributor: USB stability issues on that controller at suspend time.

**Recovery**

None needed — the drive came back cleanly on resume (`sd 0:0:0:0: [sda] Attached SCSI removable disk`).

**Prevention**

- Unmount the drive manually before suspending if it's been unstable.
- If this recurs often, suspect cable/dock/port. Try a different USB port on a different controller.

---

## Hibernate fails with `resume failed (-5)` / "Failed to load image"

**Symptom**

On boot after `systemctl hibernate`, kernel logs:

```
PM: hibernation: Read NNNN kbytes in N.N seconds (...)
PM: hibernation: Failed to load image, recovering.
PM: hibernation: resume failed (-5)
```

System cold-boots instead of restoring.

**What's actually happening**

`-5` is `EIO`. With `resume=/dev/mapper/root resume_offset=<N>` pointing into a btrfs swapfile, the most common cause is that the `resume_offset` is stale — btrfs has relocated the swapfile's physical blocks since the offset was baked into the bootloader (CoW writes, defrag, balance can all do this).

**Recovery**

None — system just cold-boots. Any unsaved work in the suspended session is lost.

**Prevention**

1. Verify the swapfile is set NOCOW (`chattr +C` on creation, before any data) and is preallocated with `fallocate` *correctly* for btrfs (or use a real swap partition / dedicated subvolume — safer).
2. Re-derive the offset:
   ```bash
   sudo filefrag -v /path/to/swapfile | awk 'NR==4 {print $4}' | tr -d '.'
   ```
3. Update the bootloader entry's `resume_offset=` to match, and regenerate (`limine-update` / `grub-mkconfig` / etc.).
4. Re-verify after any large btrfs operation (balance, defrag).
