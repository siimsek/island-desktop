#!/bin/sh
# Actions triggered from the widget. Usage: ctl.sh vol|bri <0-100> | mute | wifi | bt | ppd | lock
export LC_ALL=C.UTF-8
QD=$(command -v qdbus6 || command -v qdbus-qt6 || command -v qdbus)
BC="org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement/Actions/BrightnessControl"

# vol / bri take a percentage: refuse anything that is not a plain number.
case "$1" in
  vol|bri) case "$2" in ''|*[!0-9]*) exit 1 ;; esac ;;
esac

case "$1" in
  vol)  wpctl set-volume @DEFAULT_AUDIO_SINK@ "$2%" ;;
  mute) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
  bri)  [ -n "$QD" ] || exit 0
        M=$($QD $BC brightnessMax)
        [ "${M:-0}" -gt 0 ] || exit 0
        $QD $BC setBrightness $(( $2 * M / 100 )) ;;
  wifi) if [ "$(nmcli radio wifi)" = "enabled" ]; then nmcli radio wifi off; else nmcli radio wifi on; fi ;;
  bt)   if bluetoothctl show | grep -q "Powered: yes"; then bluetoothctl power off; else bluetoothctl power on; fi ;;
  ppd)  case "$(powerprofilesctl get)" in power-saver) powerprofilesctl set balanced;; balanced) powerprofilesctl set performance;; *) powerprofilesctl set power-saver;; esac ;;
  lock) loginctl lock-session ;;
esac
