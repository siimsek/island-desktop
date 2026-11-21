#!/usr/bin/env bash
# Applies the whole look via KDE config tools. Safe to re-run.
set -u
HERE="$(cd "$(dirname "$0")/.." && pwd)"
KW=kwriteconfig6; command -v $KW >/dev/null || KW=kwriteconfig5
QD=$(command -v qdbus6 || command -v qdbus-qt6 || command -v qdbus)

# --- colours, style, icons, cursor, fonts ---
plasma-apply-colorscheme CatppuccinMochaBlue 2>/dev/null || echo "! colour scheme CatppuccinMochaBlue not found"
plasma-apply-cursortheme catppuccin-mocha-blue-cursors 2>/dev/null || true
$KW --file kdeglobals --group Icons --key Theme IslandIcons
$KW --file kdeglobals --group KDE --key widgetStyle kvantum
$KW --file kdeglobals --group General --key font "Inter,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
$KW --file kdeglobals --group General --key menuFont "Inter,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
$KW --file kdeglobals --group WM --key activeFont "Inter,10,-1,5,600,0,0,0,0,0,0,0,0,0,0,1"
mkdir -p ~/.config/Kvantum; printf '[General]\ntheme=catppuccin-mocha-blue\n' > ~/.config/Kvantum/kvantum.kvconfig
gsettings set org.gnome.desktop.interface color-scheme prefer-dark 2>/dev/null || true
gsettings set org.gnome.desktop.interface icon-theme IslandIcons 2>/dev/null || true
gsettings set org.gnome.desktop.interface cursor-theme catppuccin-mocha-blue-cursors 2>/dev/null || true
plasma-apply-desktoptheme Island2 2>/dev/null || true
plasma-apply-wallpaperimage "$HOME/Pictures/Wallpapers/aurora-blue.svg" 2>/dev/null || true

# --- window decorations: buttons right, no hot corners ---
$KW --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft ""
$KW --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight "IAX"
for c in TopLeft TopRight BottomLeft BottomRight; do $KW --file kwinrc --group ElectricBorders --key $c None; done
for g in Effect-overview Effect-windowview Effect-desktopgrid Effect-presentwindows Effect-cube; do
  for k in BorderActivate BorderActivateAll BorderActivateClass; do $KW --file kwinrc --group $g --key $k ""; done
done

# --- KWin effects: rounded corners + acrylic blur on every window ---
$KW --file kwinrc --group Plugins --key blurEnabled false
$KW --file kwinrc --group Plugins --key better_blur_dxEnabled true
$KW --file kwinrc --group Plugins --key kwin4_effect_shapecornersEnabled true
$KW --file kwinrc --group Effect-kwin4_effect_shapecorners --key Size 16
G=Effect-better-blur-dx   # NOTE: hyphens, not underscores
for kv in "WindowClasses:" "BlurMatching:false" "BlurNonMatching:true" "BlurDecorations:true" "BlurMenus:true" "BlurDocks:false" \
          "BlurStrength:12" "NoiseStrength:3" "Saturation:130" "Brightness:100" "Contrast:100" "CornerRadius:16"; do
  $KW --file kwinrc --group $G --key "${kv%%:*}" "${kv#*:}"
done
$QD org.kde.KWin /KWin reconfigure 2>/dev/null || true
$QD org.kde.KWin /Effects unloadEffect blur 2>/dev/null || true
$QD org.kde.KWin /Effects loadEffect better_blur_dx 2>/dev/null || true
$QD org.kde.KWin /Effects loadEffect kwin4_effect_shapecorners 2>/dev/null || true

# --- Kvantum translucency, Konsole / Alacritty ---
if [ -f "$HOME/.config/Kvantum/catppuccin-mocha-blue/catppuccin-mocha-blue.kvconfig" ]; then
  sed -i 's/^translucent_windows=.*/translucent_windows=true/; s/^blurring=.*/blurring=true/; s/^reduce_window_opacity=.*/reduce_window_opacity=22/' \
    "$HOME/.config/Kvantum/catppuccin-mocha-blue/catppuccin-mocha-blue.kvconfig"
fi

# --- desktop icons: Trash + Home on the left (the dashboard widget lives on the right) ---
mkdir -p "$HOME/Desktop"
for f in "$HERE"/desktop/*.desktop; do
  sed "s|@HOME@|$HOME|" "$f" > "$HOME/Desktop/$(basename "$f")"; chmod +x "$HOME/Desktop/$(basename "$f")"
done

# --- terminal: Alacritty colours/font + Starship prompt (Catppuccin Mocha Blue). Existing files are backed up. ---
if [ "${ISLAND_TERMINAL:-1}" = 1 ]; then
  TS="$(date +%Y%m%d-%H%M%S)"
  mkdir -p ~/.config/alacritty
  [ -f ~/.config/alacritty/alacritty.toml ] && cp ~/.config/alacritty/alacritty.toml ~/.config/alacritty/alacritty.toml.bak-$TS
  cp "$HERE/terminal/alacritty/alacritty.toml" ~/.config/alacritty/alacritty.toml
  [ -f ~/.config/starship.toml ] && cp ~/.config/starship.toml ~/.config/starship.toml.bak-$TS
  cp "$HERE/terminal/starship/starship.toml" ~/.config/starship.toml
fi

# --- panels: floating pill dock + rounded top bar via Panel Colorizer ---
DOCK="$(cat "$HERE/panels/dock.json")"; TOP="$(cat "$HERE/panels/top.json")"
# The dock only lists running apps (nothing pinned); apps are started from the Meta-key launcher.
JS="
panels().forEach(function(p){p.remove();});
var top=new Panel(); top.location='top'; top.height=46; top.hiding='none'; top.lengthMode='fill';
top.addWidget('org.kde.plasma.kickoff'); top.addWidget('org.kde.plasma.panelspacer');
top.addWidget('org.kde.plasma.digitalclock'); top.addWidget('org.kde.plasma.panelspacer');
var tray=top.addWidget('org.kde.plasma.systemtray'); tray.currentConfigGroup=['General']; tray.writeConfig('shownItems',['org.kde.plasma.battery']); tray.reloadConfig();  // Plasma hides the battery icon when it is full on AC; keep it visible
var cT=top.addWidget('luisbocanegra.panel.colorizer'); cT.currentConfigGroup=['General'];
cT.writeConfig('globalSettings','$TOP'); cT.writeConfig('hideWidget','true'); cT.reloadConfig();
var dock=new Panel(); dock.location='bottom'; dock.height=64; dock.floating=true; dock.hiding='dodgewindows'; dock.alignment='center';
dock.addWidget('org.kde.plasma.panelspacer');   // spacers on both sides keep the icons centred
var t=dock.addWidget('org.kde.plasma.icontasks'); t.currentConfigGroup=['General'];
t.writeConfig('launchers',[]); t.writeConfig('iconSpacing',3); t.writeConfig('showOnlyCurrentDesktop',false); t.writeConfig('showOnlyCurrentScreen',false); t.writeConfig('showOnlyCurrentActivity',false); t.reloadConfig();
dock.addWidget('org.kde.plasma.panelspacer');
var cD=dock.addWidget('luisbocanegra.panel.colorizer'); cD.currentConfigGroup=['General'];
cD.writeConfig('globalSettings','$DOCK'); cD.writeConfig('hideWidget','true'); cD.reloadConfig();
// The panel is a wide, invisible hit area (auto-hide trigger zone, >= 2x the pill up to ~4 apps);
// the visible pill is drawn by Panel Colorizer around the task icons only, so it stays as narrow as the apps.
dock.lengthMode='custom'; dock.minimumLength=480; dock.maximumLength=480;
top.floating=false;   // only the top bar is docked flush; the dock above floats
var d=desktops()[0];
d.widgetIds.forEach(function(i){var w=d.widgetById(i); if(w.type!='org.kde.plasma.folder') w.remove();});
var sw=(typeof screenGeometry=='function')?screenGeometry(d.screen).width:1920;
var w=d.addWidget('org.local.islanddash',Math.max(64,sw-772-64),70,772,700); w.userBackgroundHints='NoBackground';
d.currentConfigGroup=['General']; d.writeConfig('alignment',0); d.reloadConfig();
"
$QD org.kde.plasmashell /PlasmaShell evaluateScript "$JS" >/dev/null 2>&1 || echo "! panel script failed (is plasmashell running?)"
echo "Done. Log out and back in to finish applying everything."
