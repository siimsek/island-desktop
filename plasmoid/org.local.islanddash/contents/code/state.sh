#!/bin/sh
# Prints key=value lines describing system state. Distro-agnostic where possible.
export LC_ALL=C
QD=$(command -v qdbus6 || command -v qdbus-qt6 || command -v qdbus)
V=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
echo "vol=$(echo "$V" | awk '{printf "%d",$2*100}')"
echo "mute=$(echo "$V" | grep -c MUTED)"
if [ -n "$QD" ]; then
  B=$($QD org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement/Actions/BrightnessControl brightness 2>/dev/null)
  M=$($QD org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement/Actions/BrightnessControl brightnessMax 2>/dev/null)
  [ -n "$B" ] && [ -n "$M" ] && [ "$M" -gt 0 ] && echo "bri=$((B*100/M))"
fi
echo "wifi=$(nmcli radio wifi 2>/dev/null)"
echo "bt=$(bluetoothctl show 2>/dev/null | awk '/Powered:/{print $2}')"
echo "ppd=$(powerprofilesctl get 2>/dev/null)"
BAT=$(upower -e 2>/dev/null | grep -iE 'battery_bat' | head -1)
if [ -n "$BAT" ]; then
  upower -i "$BAT" | awk -F': *' '
    /^ *state:/{s=$2} /^ *percentage:/{p=$2} /^ *capacity:/{c=$2}
    /^ *energy:/{split($2,a," ");e=a[1]} /^ *energy-full:/{split($2,a," ");f=a[1]}
    /^ *energy-rate:/{split($2,a," ");w=a[1]} /^ *voltage:/{split($2,a," ");v=a[1]}
    END{gsub("%","",p); gsub("%","",c); print "bat=" p "|" s "|" e "|" f "|" w "|" v "|" c}'
fi
for d in $(upower -e 2>/dev/null | grep -vE 'DisplayDevice|line_power|battery_bat|battery_BAT'); do
  upower -i "$d" | awk -F': *' '
    /^ *model:/{m=$2} /^ *vendor:/{v=$2} /^ *percentage:/{p=$2} /^ *state:/{s=$2}
    END{ gsub("%","",p); if (p!="") { n=m; if(n=="") n=v; if(n=="") n="Cihaz"; print "dev=" n "|" p "|" s } }'
done
