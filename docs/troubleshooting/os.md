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

---

## minidlna: "Media directory not accessible [Permission denied]" (on `orek`)

**Symptom**

minidlna (DLNA server, media on the EXT4 external drive) fails to index after a
reboot or every time the drive is re-plugged. Journal shows:

```
minidlnad[...]: error: Media directory "/run/media/adam/9b5330ad-.../media" not accessible [Permission denied]
```

The media dir itself is `0775 adam:adam` (readable), so the error is misleading.

**What's actually happening**

udisks mounts the drive under `/run/media/adam`, and creates that per-user
parent directory as `drwxr-x---+ root root` with an ACL that grants **only
`adam`** (`getfacl` shows `user:adam:r-x`, `other::---`). The stock
`minidlna.service` ships `DynamicUser=yes`, so it runs as a random transient
UID — which is "other" here and **cannot traverse `/run/media/adam`** to reach
the media dir underneath. It recurs on every mount because udisks recreates that
locked-down parent each time.

**How to check**

```bash
getfacl /run/media/adam                 # other::--- , only user:adam:r-x
systemctl show minidlna -p DynamicUser  # DynamicUser=yes  -> the problem
```

**Fix (run minidlna as `adam` + bind it to the drive)**

Two systemd drop-ins, tracked in this repo under
`etc/systemd/system/` (mirroring their real paths). They are **not** auto-symlinked
by `install-arch.sh` (orek-only), so deploy them by hand:

```bash
D=~/dev/devconfig/etc/systemd/system
sudo cp -r "$D"/minidlna.service.d /etc/systemd/system/
sudo cp -r "$D"/'run-media-adam-9b5330ad\x2d7662\x2d4a10\x2d90e8\x2d1d1ae68dea15.mount.d' /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl disable minidlna       # the drive mount now drives it, not boot
sudo systemctl restart minidlna
```

- `minidlna.service.d/10-run-as-adam.conf` — `DynamicUser=no` + `User=adam`
  (adam always holds the udisks ACL, so it survives every remount). Also
  `BindsTo=`/`After=` the drive's mount unit → stops cleanly on unplug.
- `run-media-adam-<UUID>.mount.d/50-start-minidlna.conf` — `Upholds=minidlna.service`
  on the udisks mount unit → **auto-starts minidlna whenever the drive mounts**.
  The dir name is the systemd-escaped mount path (`\x2d` = `-`); regenerate with
  `systemd-escape -p --suffix=mount /run/media/adam/<UUID>` if the UUID changes.

Net effect: minidlna's whole lifecycle follows the removable drive — up on plug,
down on unplug, no boot-time errors when the drive is absent.

**Side effects / notes**

- With `DynamicUser=no`, the DB cache moves from `/var/cache/private/minidlna`
  back to `/var/cache/minidlna`. Force a clean re-index if it complains:
  `sudo systemctl stop minidlna && sudo rm -f /var/cache/minidlna/files.db && sudo systemctl start minidlna`.
- media_dir lives in `/etc/minidlna.conf` (not tracked here — points at the
  drive's UUID path).
- Status page rejects `Host: localhost` as DNS-rebinding; query with the LAN IP:
  `curl -H "Host: 192.168.1.69:8200" http://127.0.0.1:8200/`.

**Fallback if auto-start-on-plug ever fails**

The `Upholds=` drop-in relies on systemd honoring a drop-in on a udisks-generated
mount unit (it does here — `systemctl show <mount> -p Upholds` confirms). If a
future systemd/udisks change breaks that, replace it with a UUID-keyed udev rule:

```
# /etc/udev/rules.d/99-minidlna.rules
ACTION=="add", SUBSYSTEM=="block", ENV{ID_FS_UUID}=="9b5330ad-7662-4a10-90e8-1d1ae68dea15", \
  RUN+="/usr/bin/systemctl --no-block restart minidlna.service"
```
