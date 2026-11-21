#!/usr/bin/env bash
# Removes what install.sh put in your home directory. Does not touch installed packages or your panels.
set -u
kwriteconfig6 --file kwinrc --group Plugins --key dock-hide-when-emptyEnabled false 2>/dev/null
rm -rf ~/.local/share/plasma/plasmoids/org.local.islanddash ~/.local/share/plasma/desktoptheme/Island2 ~/.local/share/kwin/scripts/dock-hide-when-empty \
       ~/.local/share/icons/IslandIcons ~/.local/share/konsole/CatppuccinMocha.colorscheme ~/Pictures/Wallpapers/aurora-blue.svg
if [ "${1:-}" = "--power" ]; then
  sudo rm -f /usr/local/bin/power-auto /etc/udev/rules.d/99-power-auto.rules /etc/NetworkManager/conf.d/wifi-powersave.conf
  sudo udevadm control --reload
fi
echo "Removed. Reset your look in System Settings (Appearance) and re-add your panels if needed."
