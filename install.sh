#!/usr/bin/env bash
# island-desktop installer for KDE Plasma 6
#   ./install.sh                 theme + KWin effects + widget + settings
#   ./install.sh --power         also install the AC/battery profile switcher (laptops, needs sudo)
#   ./install.sh --skip-effects  do not build the KWin effects (rounded corners / Better Blur)
#   ./install.sh --no-apply      install files but do not touch your panels/settings
#   ./install.sh --no-terminal   keep your own Alacritty / Starship config
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
POWER=0; EFFECTS=1; APPLY=1
for a in "$@"; do case "$a" in --power) POWER=1;; --skip-effects) EFFECTS=0;; --no-apply) APPLY=0;; --no-terminal) export ISLAND_TERMINAL=0;; -h|--help) sed -n 2,8p "$0"; exit 0;; esac; done

say()  { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m  ! %s\033[0m\n' "$*"; FAILED+=("$*"); }
FAILED=()

. /etc/os-release
case " ${ID:-} ${ID_LIKE:-} " in
  *" arch "*|*" cachyos "*|*" manjaro "*|*" endeavouros "*) PM=pacman ;;
  *" debian "*|*" ubuntu "*|*" neon "*)                      PM=apt ;;
  *" fedora "*|*" rhel "*)                                   PM=dnf ;;
  *" suse "*|*" opensuse "*)                                 PM=zypper ;;
  *) echo "Unsupported distro (${ID:-?}). Install the dependencies listed in README.md manually."; exit 1 ;;
esac
command -v plasmashell >/dev/null || { echo "KDE Plasma 6 is required."; exit 1; }
PV="$(plasmashell --version 2>/dev/null | grep -oE '[0-9]+' | head -1)"
[ "${PV:-0}" -ge 6 ] || { echo "Plasma 6 required (found ${PV:-none})."; exit 1; }
echo "Distro family: $PM | Plasma $(plasmashell --version | awk '{print $2}')"

# Install packages one by one so a single wrong name never aborts everything.
pm_install() {
  for p in "$@"; do
    case "$PM" in
      pacman) if command -v paru >/dev/null; then paru -S --needed --noconfirm "$p"; else sudo pacman -S --needed --noconfirm "$p"; fi ;;
      apt)    sudo apt-get install -y "$p" ;;
      dnf)    sudo dnf install -y "$p" ;;
      zypper) sudo zypper --non-interactive install "$p" ;;
    esac >/dev/null 2>&1 || warn "package not installed: $p"
  done
}
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
FONTS=~/.local/share/fonts; ICONS=~/.local/share/icons

say "Base packages"
case "$PM" in
  pacman) pm_install git cmake extra-cmake-modules qt6-tools kwin libepoxy vulkan-headers kcmutils kio knotifications kcrash kglobalaccel \
                     kvantum inter-font ttf-jetbrains-mono-nerd upower power-profiles-daemon thermald ;;
  apt)    pm_install git cmake extra-cmake-modules qt6-tools-dev kwin-dev libepoxy-dev libvulkan-dev libkf6kcmutils-dev libkf6kio-dev \
                     libkf6notifications-dev libkf6crash-dev libkf6globalaccel-dev qt6-style-kvantum fonts-inter upower power-profiles-daemon thermald ;;
  dnf)    pm_install git cmake extra-cmake-modules qt6-qttools-devel kwin-devel libepoxy-devel vulkan-headers kf6-kcmutils-devel kf6-kio-devel \
                     kf6-knotifications-devel kf6-kcrash-devel kf6-kglobalaccel-devel kvantum rsms-inter-fonts upower power-profiles-daemon thermald ;;
  zypper) pm_install git cmake extra-cmake-modules qt6-tools-devel kwin6-devel libepoxy-devel vulkan-headers kvantum-qt6 inter-fonts upower power-profiles-daemon thermald ;;
esac

say "Fonts (JetBrains Mono Nerd Font)"
if ! fc-list | grep -qi "JetBrainsMono Nerd"; then
  mkdir -p "$FONTS"
  curl -fsSL -o "$TMP/jb.zip" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip \
    && unzip -oq "$TMP/jb.zip" -d "$FONTS/JetBrainsMonoNerd" && fc-cache -f >/dev/null || warn "could not install JetBrains Mono Nerd Font"
fi

say "Catppuccin colours, Kvantum theme, cursors"
if [ "$PM" = pacman ] && command -v paru >/dev/null; then
  pm_install catppuccin-plasma-colorscheme-mocha catppuccin-cursors-mocha kvantum-theme-catppuccin-git
else
  mkdir -p ~/.local/share/color-schemes ~/.config/Kvantum "$ICONS"
  git clone -q --depth=1 https://github.com/catppuccin/kde.git "$TMP/kde" \
    && cp "$TMP/kde/generated/color-schemes/CatppuccinMochaBlue.colors" ~/.local/share/color-schemes/ || warn "colour scheme download failed"
  git clone -q --depth=1 https://github.com/catppuccin/Kvantum.git "$TMP/kv" \
    && cp -r "$TMP/kv/themes/catppuccin-mocha-blue" ~/.config/Kvantum/ || warn "Kvantum theme download failed"
  curl -fsSL -o "$TMP/cur.zip" https://github.com/catppuccin/cursors/releases/latest/download/catppuccin-mocha-blue-cursors.zip \
    && unzip -oq "$TMP/cur.zip" -d "$ICONS" || warn "cursor theme download failed"
fi

say "Icons: WhiteSur app icons + status icons -> IslandIcons (Papirus-Dark fills gaps)"
pm_install papirus-icon-theme
I="$ICONS/IslandIcons"
if git clone -q --depth=1 https://github.com/vinceliuice/WhiteSur-icon-theme.git "$TMP/ws"; then
  # WhiteSur base theme (squircle app icons). Plain file copies, same set as its own installer; its script is never run.
  W="$ICONS/WhiteSur"; rm -rf "$W"; mkdir -p "$W/status"
  cp "$TMP/ws/src/index.theme" "$W/"
  cp -r "$TMP/ws"/src/{actions,animations,apps,categories,devices,emotes,emblems,mimes,places,preferences} "$W/"
  cp -r "$TMP/ws"/src/status/{16,22,24,32,symbolic} "$W/status/"
  cp -r "$TMP/ws"/links/{actions,apps,categories,devices,emotes,emblems,mimes,places,status,preferences} "$W/"
  rm -f "$W"/places/scalable/user-trash{,-full}-dark.svg
  gtk-update-icon-cache -f "$W" >/dev/null 2>&1 || true
  # WhiteSur-dark: same glyphs recoloured light (#363636 -> #dedede) so menu / category / action icons stay readable on a dark UI
  Dk="$ICONS/WhiteSur-dark"; rm -rf "$Dk"; mkdir -p "$Dk"/{apps,categories,emblems,devices,mimes,places,status}
  cp "$TMP/ws/src/index.theme" "$Dk/"; sed -i "s/WhiteSur/WhiteSur-dark/g" "$Dk/index.theme"
  cp -r "$TMP/ws/src/actions" "$Dk"
  cp -r "$TMP/ws"/src/apps/{16,22,32,symbolic} "$Dk/apps"
  cp -r "$TMP/ws"/src/categories/{22,symbolic} "$Dk/categories"
  cp -r "$TMP/ws/src/emblems/symbolic" "$Dk/emblems"; cp -r "$TMP/ws/src/mimes/symbolic" "$Dk/mimes"
  cp -r "$TMP/ws"/src/devices/{16,22,24,32,symbolic} "$Dk/devices"
  cp -r "$TMP/ws"/src/places/{16,22,24,scalable,symbolic} "$Dk/places"
  cp -r "$TMP/ws/src/status/symbolic" "$Dk/status"
  mv -f "$Dk/places/scalable/user-trash-dark.svg" "$Dk/places/scalable/user-trash.svg"
  mv -f "$Dk/places/scalable/user-trash-full-dark.svg" "$Dk/places/scalable/user-trash-full.svg"
  sed -i "s/#363636/#dedede/g" "$Dk"/{actions,devices,places}/{16,22,24}/*.svg "$Dk"/apps/{16,22,32}/*.svg "$Dk"/categories/22/*.svg "$Dk"/{actions,devices}/32/*.svg
  sed -i "s/#363636/#dedede/g" "$Dk"/{actions,apps,categories,emblems,devices,mimes,places,status}/symbolic/*.svg
  cp -r "$TMP/ws"/links/actions/{16,22,24,32,symbolic} "$Dk/actions"; cp -r "$TMP/ws"/links/devices/{16,22,24,32,symbolic} "$Dk/devices"
  cp -r "$TMP/ws"/links/places/{16,22,24,scalable,symbolic} "$Dk/places"; cp -r "$TMP/ws"/links/apps/{16,22,32,symbolic} "$Dk/apps"
  cp -r "$TMP/ws"/links/categories/{22,symbolic} "$Dk/categories"; cp -r "$TMP/ws/links/emblems/symbolic" "$Dk/emblems"
  cp -r "$TMP/ws/links/mimes/symbolic" "$Dk/mimes"; cp -r "$TMP/ws/links/status/symbolic" "$Dk/status"
  ( cd "$Dk"
    for x in animations emotes preferences; do ln -sfn ../WhiteSur/$x $x; done
    ln -sfn ../../WhiteSur/categories/32 categories/32
    for z in 16 22 24; do ln -sfn ../../WhiteSur/emblems/$z emblems/$z; ln -sfn ../../WhiteSur/status/$z status/$z; done
    ln -sfn ../../WhiteSur/status/32 status/32
    for z in 16 22; do ln -sfn ../../WhiteSur/mimes/$z mimes/$z; done
    ln -sfn ../../WhiteSur/mimes/scalable mimes/scalable; ln -sfn ../../WhiteSur/apps/scalable apps/scalable; ln -sfn ../../WhiteSur/devices/scalable devices/scalable
    for c in actions animations apps categories devices emotes emblems mimes places preferences status; do ln -sfn $c $c@2x; done )
  gtk-update-icon-cache -f "$Dk" >/dev/null 2>&1 || true
  rm -rf "$I"; mkdir -p "$I"
  # same file set WhiteSur's own installer copies for its default (light-on-dark) variant, without running its script
  cp -a "$TMP/ws/src/status" "$TMP/ws/src/devices" "$I/"
  for c in status devices; do for s in 16 22 24 32; do [ -d "$TMP/ws/links/$c/$s" ] && cp -a "$TMP/ws/links/$c/$s/." "$I/$c/$s/"; done; done
  DIRS="status/symbolic devices/symbolic status/16 status/22 status/24 status/32 devices/16 devices/22 devices/24 devices/32"
  { printf '[Icon Theme]\nName=IslandIcons\nComment=WhiteSur app icons with iOS-style status icons\nInherits=WhiteSur-dark,WhiteSur,Papirus-Dark,hicolor\nDirectories=%s\n\n' "${DIRS// /,}"
    for d in $DIRS; do
      c=Status; [[ $d == devices* ]] && c=Devices
      if [[ $d == */symbolic ]]; then printf '[%s]\nSize=16\nContext=%s\nMinSize=16\nMaxSize=512\nType=Scalable\n\n' "$d" "$c"
      else printf '[%s]\nSize=%s\nContext=%s\nType=Fixed\n\n' "$d" "${d##*/}" "$c"; fi
    done; } > "$I/index.theme"
  gtk-update-icon-cache -f "$I" >/dev/null 2>&1 || true
else warn "WhiteSur icon download failed (app and status icons will fall back to Papirus/Breeze)"; fi

say "Panel Colorizer plasmoid"
if ! kpackagetool6 --type Plasma/Applet --list 2>/dev/null | grep -q panel.colorizer && [ ! -d /usr/share/plasma/plasmoids/luisbocanegra.panel.colorizer ]; then
  if [ "$PM" = pacman ] && command -v paru >/dev/null; then pm_install plasma6-applets-panel-colorizer
  else git clone -q --depth=1 https://github.com/luisbocanegra/plasma-panel-colorizer.git "$TMP/pc" \
         && kpackagetool6 --type Plasma/Applet --install "$TMP/pc/package" >/dev/null 2>&1 || warn "Panel Colorizer install failed (add it from 'Get New Widgets')"; fi
fi

if [ "$EFFECTS" = 1 ]; then say "KWin effects (rounded corners + Better Blur) - built against this machine's KWin"; bash "$HERE/scripts/build-kwin-effects.sh" || warn "KWin effects build failed"; fi

say "Assets (widget, Plasma theme, Konsole scheme, wallpaper)"
mkdir -p ~/.local/share/plasma/plasmoids ~/.local/share/plasma/desktoptheme ~/.local/share/konsole ~/Pictures/Wallpapers
rm -rf ~/.local/share/plasma/plasmoids/org.local.islanddash ~/.local/share/plasma/desktoptheme/Island2
cp -r "$HERE/plasmoid/org.local.islanddash" ~/.local/share/plasma/plasmoids/
cp -r "$HERE/plasma/desktoptheme/Island2" ~/.local/share/plasma/desktoptheme/
cp "$HERE"/konsole/*.colorscheme ~/.local/share/konsole/
cp "$HERE"/wallpapers/*.svg ~/Pictures/Wallpapers/

if [ "$POWER" = 1 ]; then
  say "Power tweaks (AC/battery)"
  sudo install -m755 "$HERE/power/power-auto" /usr/local/bin/power-auto
  sudo install -m644 "$HERE/power/99-power-auto.rules" /etc/udev/rules.d/99-power-auto.rules
  sudo mkdir -p /etc/NetworkManager/conf.d && sudo install -m644 "$HERE/power/wifi-powersave.conf" /etc/NetworkManager/conf.d/
  sudo udevadm control --reload
  sudo systemctl enable --now thermald power-profiles-daemon >/dev/null 2>&1 || warn "could not enable thermald/power-profiles-daemon"
fi

if [ "$APPLY" = 1 ]; then say "Applying settings"; bash "$HERE/scripts/apply-settings.sh"; fi

say "Done"
if [ ${#FAILED[@]} -gt 0 ]; then printf 'Some steps need attention:\n'; printf '  - %s\n' "${FAILED[@]}"; fi
echo "Log out and back in to finish applying everything."
