#!/bin/sh
QD=$(command -v qdbus6 || command -v qdbus-qt6 || command -v qdbus)
case "$1" in
  vol)  wpctl set-volume @DEFAULT_AUDIO_SINK@ "$2%" ;;
  mute) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
  bri)  M=$($QD org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement/Actions/BrightnessControl brightnessMax)
        $QD org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement/Actions/BrightnessControl setBrightness $(( $2 * M / 100 )) ;;
  wifi) [ "$(nmcli radio wifi)" = "enabled" ] && nmcli radio wifi off || nmcli radio wifi on ;;
  bt)   if bluetoothctl show | grep -q "Powered: yes"; then bluetoothctl power off; else bluetoothctl power on; fi ;;
  ppd)  case "$(powerprofilesctl get)" in power-saver) powerprofilesctl set balanced;; balanced) powerprofilesctl set performance;; *) powerprofilesctl set power-saver;; esac ;;
  lock) loginctl lock-session ;;
esac
