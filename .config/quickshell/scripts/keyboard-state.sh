#!/usr/bin/env bash
# State of the Lily58 split keyboard for the quickshell HUD.
# Output: "<link>|<Lpct>|<Rpct>"  e.g. "usb|85|72", "ble|90|--", "off|--|--"
#   link: usb (left half on USB), ble (BT connected), off (neither)
#   Lpct/Rpct: battery percent of each half, or -- when unknown.
#
# The left/central proxies the right's battery as a second BLE battery-service
# instance (CONFIG_ZMK_SPLIT_BLE_CENTRAL_BATTERY_LEVEL_PROXY). BlueZ surfaces
# the primary via org.bluez.Battery1; the second instance is read from the
# GATT characteristic (UUID 2a19) if BlueZ exposes it.

MAC="E8:0C:B3:F6:66:10"                       # left/central, host-facing
DEV="dev_${MAC//:/_}"
LEFT_USB_SERIAL="3A8F02D9AD37EF58"

link="off"
# USB: left half enumerated as 1d50:615e with the left's serial.
if grep -qs "$LEFT_USB_SERIAL" /sys/bus/usb/devices/*/serial 2>/dev/null; then
    link="usb"
fi

lpct="--"; rpct="--"

if bluetoothctl info "$MAC" 2>/dev/null | grep -q 'Connected: yes'; then
    [ "$link" = "off" ] && link="ble"
    # Primary battery (left/central) via org.bluez.Battery1.
    pct=$(busctl get-property org.bluez "/org/bluez/hci0/$DEV" \
          org.bluez.Battery1 Percentage 2>/dev/null | awk '{print $2}')
    [ -n "$pct" ] && lpct="$pct"
    # Secondary battery instances (peripheral proxy): scan GATT chars with the
    # battery_level UUID and read each; first extra one is the right half.
    extra=$(busctl tree org.bluez 2>/dev/null | grep -oE "/org/bluez/hci0/$DEV/service[0-9a-f]+/char[0-9a-f]+" | while read -r path; do
        uuid=$(busctl get-property org.bluez "$path" org.bluez.GattCharacteristic1 UUID 2>/dev/null | grep -oE '"[^"]+"' | tr -d '"')
        if [ "$uuid" = "00002a19-0000-1000-8000-00805f9b34fb" ]; then
            busctl call org.bluez "$path" org.bluez.GattCharacteristic1 ReadValue 'a{sv}' 0 2>/dev/null | awk '{print $NF}'
        fi
    done | tail -1)
    [ -n "$extra" ] && rpct="$extra"
fi

echo "${link}|${lpct}|${rpct}"
