#!/bin/sh
# Prints key=value lines describing system state. Distro-agnostic where possible.
# Polled every 10 s by the widget.
#
# C.UTF-8 keeps tool output parseable (dot decimals, English labels). Plain
# LC_ALL=C made every qdbus call log "Detected locale C ... not UTF-8" to the journal.
export LC_ALL=C.UTF-8
# A hung nmcli / bluetoothctl / upower must never stall the poll: the widget would
# keep the source "connected" and stop refreshing until the session restarts.
T="timeout 3"
QD=$(command -v qdbus6 || command -v qdbus-qt6 || command -v qdbus)

V=$($T wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
echo "vol=$(echo "$V" | awk '{printf "%d",$2*100}')"
echo "mute=$(echo "$V" | grep -c MUTED)"
if [ -n "$QD" ]; then
  BC="org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement/Actions/BrightnessControl"
  B=$($T $QD $BC brightness 2>/dev/null)
  M=$($T $QD $BC brightnessMax 2>/dev/null)
  [ -n "$B" ] && [ -n "$M" ] && [ "$M" -gt 0 ] && echo "bri=$((B*100/M))"
fi
echo "wifi=$($T nmcli radio wifi 2>/dev/null)"
echo "bt=$($T bluetoothctl show 2>/dev/null | awk '/Powered:/{print $2}')"
echo "ppd=$($T powerprofilesctl get 2>/dev/null)"

UP=$($T upower -e 2>/dev/null)   # enumerate once, reuse for battery and peripherals
BAT=$(printf '%s\n' "$UP" | grep -iE 'battery_bat' | head -1)
if [ -n "$BAT" ]; then
  $T upower -i "$BAT" | awk -F': *' '
    /^ *state:/{s=$2} /^ *percentage:/{p=$2} /^ *capacity:/{c=$2}
    /^ *energy:/{split($2,a," ");e=a[1]} /^ *energy-full:/{split($2,a," ");f=a[1]}
    /^ *energy-rate:/{split($2,a," ");w=a[1]} /^ *voltage:/{split($2,a," ");v=a[1]}
    END{gsub("%","",p); gsub("%","",c); print "bat=" p "|" s "|" e "|" f "|" w "|" v "|" c}'
fi
printf '%s\n' "$UP" | grep -vE 'DisplayDevice|line_power|battery_bat|battery_BAT' | while read -r d; do
  [ -n "$d" ] || continue
  $T upower -i "$d" | awk -F': *' '
    /^ *model:/{m=$2} /^ *vendor:/{v=$2} /^ *percentage:/{p=$2} /^ *state:/{s=$2}
    END{ gsub("%","",p); if (p!="") { n=m; if(n=="") n=v; if(n=="") n="Cihaz"; print "dev=" n "|" p "|" s } }'
done
