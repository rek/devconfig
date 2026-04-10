#!/usr/bin/python3
"""Apply monitor layout via GNOME Mutter DisplayConfig D-Bus API.

Auto-detects connected displays by vendor/product/resolution and applies
the appropriate layout:
  - Glasses found:    Philips (portrait) + Glasses + Laptop
  - No glasses:       Philips (portrait) + 2nd monitor + Laptop
  - Two displays:     Philips (portrait) + Laptop
"""
import sys
import dbus

bus = dbus.SessionBus()
obj = bus.get_object('org.gnome.Mutter.DisplayConfig',
                     '/org/gnome/Mutter/DisplayConfig')
disp = dbus.Interface(obj, 'org.gnome.Mutter.DisplayConfig')

serial, monitors, logical_monitors, props = disp.GetCurrentState()

# ── Classify monitors ─────────────────────────────────────────────────────────

laptop = None
philips = None
glasses = None
others = []

for (conn, vendor, product, ser), modes, mprops in monitors:
    conn, vendor, product = str(conn), str(vendor), str(product)
    ident = (vendor + ' ' + product).lower()

    mode_map = {}
    preferred_res = None
    for mode in modes:
        mid, w, h = str(mode[0]), int(mode[1]), int(mode[2])
        mode_map[(w, h)] = mid
        # mode[6] is properties dict — check for is-current / is-preferred
        mflags = mode[6] if len(mode) > 6 else {}
        if mflags.get('is-current', False):
            preferred_res = (w, h)
        elif preferred_res is None and mflags.get('is-preferred', False):
            preferred_res = (w, h)
    if preferred_res is None and mode_map:
        preferred_res = next(iter(mode_map))

    info = {'conn': conn, 'vendor': vendor, 'product': product,
            'modes': mode_map, 'preferred': preferred_res}

    if conn.startswith('eDP'):
        laptop = info
    elif 'xreal' in ident or 'nreal' in ident:
        glasses = info
    elif 'phl' in ident or 'philips' in ident:
        philips = info
    else:
        others.append(info)

# Fallback: identify Philips by its native resolution if vendor didn't match
if not philips:
    for i, o in enumerate(others):
        if (2560, 1440) in o['modes']:
            philips = others.pop(i)
            break

# ── Report ────────────────────────────────────────────────────────────────────

for label, mon in [('Laptop', laptop), ('Philips', philips), ('Glasses', glasses)]:
    if mon:
        print(f"  {label}: {mon['conn']} ({mon['vendor']} {mon['product']})")
for o in others:
    print(f"  Other:  {o['conn']} ({o['vendor']} {o['product']})")

if not laptop or not philips:
    print("ERROR: need at least laptop + Philips monitor", file=sys.stderr)
    print(f"  Found: {[m['conn'] for m in [laptop, philips, glasses] if m] + [o['conn'] for o in others]}", file=sys.stderr)
    sys.exit(1)

# Print machine-readable flag for the shell wrapper
if glasses:
    print("HAS_GLASSES")

# ── Build layout ──────────────────────────────────────────────────────────────

lm_entries = []


def add_monitor(mon, res, x, y, scale, transform, primary):
    if res not in mon['modes']:
        # Fall back to best available
        res = max(mon['modes'].keys(), key=lambda r: r[0] * r[1])
        print(f"  Warning: {mon['conn']} wanted mode not found, using {res[0]}x{res[1]}")
    mid = mon['modes'][res]
    monitor_entry = dbus.Array(
        [(dbus.String(mon['conn']), dbus.String(mid),
          dbus.Dictionary({}, signature='sv'))],
        signature='(ssa{sv})')
    lm_entries.append((
        dbus.Int32(x), dbus.Int32(y), dbus.Double(scale),
        dbus.UInt32(transform), dbus.Boolean(primary),
        monitor_entry))


# Philips portrait-left at origin  (rotated = 1440w × 2560h)
add_monitor(philips, (2560, 1440), 0, 0, 1.0, 1, False)

# Laptop below Philips, centered
add_monitor(laptop, (1920, 1200), 795, 2560, 1.0, 0, True)

# Third display: glasses or second monitor
third = glasses or (others[0] if others else None)
if third:
    if third is glasses:
        res = (1920, 1080)
    else:
        res = third['preferred']
    # Bottom-align with Philips (portrait height 2560)
    y = max(0, 2560 - res[1])
    print(f"  Third:  {third['conn']} at {res[0]}x{res[1]}, pos 1440x{y}")
    add_monitor(third, res, 1440, y, 1.0, 0, False)
else:
    print("  Layout: Philips + Laptop only")

# ── Apply (method=2 = persistent) ────────────────────────────────────────────

disp.ApplyMonitorsConfig(
    dbus.UInt32(serial),
    dbus.UInt32(2),
    dbus.Array(lm_entries, signature='(iiduba(ssa{sv}))'),
    dbus.Dictionary({}, signature='sv'))
print("Layout applied.")
