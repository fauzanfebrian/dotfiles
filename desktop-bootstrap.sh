#!/bin/bash
# Desktop bootstrap: macOS-inspired theming, dock, keybindings, and UX for Cinnamon.
# Run as your normal user (no sudo). The script will invoke sudo where needed.

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if [[ "${EUID:-}" -eq 0 ]]; then
    echo -e "${YELLOW}Do not run as root. Run as your normal user: ./desktop-bootstrap.sh${NC}"
    exit 1
fi

# ==========================================
# 1. DEPENDENCIES & REPOSITORIES
# ==========================================
install_deps() {
    echo -e "${BLUE}>>> Phase 1: Dependencies & repositories${NC}"

    if ! grep -q 'papirus/papirus' /etc/apt/sources.list.d/*.list 2>/dev/null; then
        echo "---> Adding Papirus PPA..."
        sudo add-apt-repository ppa:papirus/papirus -y
    else
        echo -e "${YELLOW}---> Papirus PPA already present. Skipping.${NC}"
    fi

    sudo apt-get update
    sudo apt-get install -y plank papirus-icon-theme peek python3 fonts-inter
}

# ==========================================
# 2. VISUALS, THEMING & TYPOGRAPHY
# ==========================================
apply_theme() {
    echo -e "${BLUE}>>> Phase 2: Visuals, theming & typography${NC}"

    # Dark mode and Papirus icons
    gsettings set org.cinnamon.desktop.interface gtk-theme 'Mint-Y-Dark'
    gsettings set org.cinnamon.desktop.wm.preferences theme 'Mint-Y-Dark'
    gsettings set org.cinnamon.theme name 'Mint-Y-Dark'
    gsettings set org.cinnamon.desktop.interface icon-theme 'Papirus-Dark'

    # Typography (Inter Font + Mac-style anti-aliasing)
    gsettings set org.cinnamon.settings-daemon.plugins.xsettings hinting 'none'
    gsettings set org.cinnamon.settings-daemon.plugins.xsettings antialiasing 'rgba'
    gsettings set org.gnome.desktop.interface font-hinting 'none'
    gsettings set org.gnome.desktop.interface font-antialiasing 'rgba'
    gsettings set org.cinnamon.desktop.interface font-name 'Inter 10'
    gsettings set org.cinnamon.desktop.wm.preferences titlebar-font 'Inter Bold 10'

    # Fontconfig X11 layer (forces browsers and IDEs to comply)
    mkdir -p ~/.config/fontconfig
    cat <<'EOF' > ~/.config/fontconfig/fonts.conf
<?xml version='1.0'?>
<!DOCTYPE fontconfig SYSTEM 'fonts.dtd'>
<fontconfig>
  <match target="font">
    <edit name="antialias" mode="assign"><bool>true</bool></edit>
    <edit name="hinting" mode="assign"><bool>false</bool></edit>
    <edit name="rgba" mode="assign"><const>rgb</const></edit>
    <edit name="lcdfilter" mode="assign"><const>lcddefault</const></edit>
  </match>
</fontconfig>
EOF

    echo -e "${GREEN}---> Theme and typography applied.${NC}"
}

# ==========================================
# 3. BEHAVIORAL SYNC (MAC MUSCLE MEMORY)
# ==========================================
apply_behavior() {
    echo -e "${BLUE}>>> Phase 3: Behavioral sync (macOS muscle memory)${NC}"

    gsettings set org.cinnamon.desktop.peripherals.touchpad natural-scroll true
    gsettings set org.cinnamon.desktop.peripherals.mouse natural-scroll true
    gsettings set org.cinnamon.desktop.wm.preferences button-layout 'close,minimize,maximize:'

    echo -e "${GREEN}---> Natural scroll and left-side window controls set.${NC}"
}

# ==========================================
# 4. PANEL & DOCK ARCHITECTURE
# ==========================================
setup_dock() {
    echo -e "${BLUE}>>> Phase 4: Panel & dock architecture${NC}"

    # Auto-hide top panel — read current panel IDs instead of hardcoding
    PANEL_IDS=$(dconf read /org/cinnamon/panels-enabled 2>/dev/null || echo "")
    if [[ -n "$PANEL_IDS" ]]; then
        FIRST_PANEL_ID=$(python3 -c "
import ast, sys
raw = sys.argv[1]
panels = ast.literal_eval(raw) if raw.strip() not in ('', '[]') else []
if panels:
    print(panels[0].split(':')[0])
" "$PANEL_IDS" 2>/dev/null || echo "1")
        dconf write /org/cinnamon/panels-autohide "['${FIRST_PANEL_ID}:intel']"
        echo "---> Auto-hiding panel ${FIRST_PANEL_ID}."
    else
        echo -e "${YELLOW}---> Could not detect panel IDs. Setting default auto-hide for panel 1.${NC}"
        dconf write /org/cinnamon/panels-autohide "['1:intel']"
    fi

    # Plank dock — centered, no monitor lock
    dconf write /net/launchpad/plank/docks/dock1/monitor "''"

    # Plank autostart
    mkdir -p ~/.config/autostart
    cat <<EOF > ~/.config/autostart/plank.desktop
[Desktop Entry]
Name=Plank
Exec=plank
Type=Application
X-GNOME-Autostart-enabled=true
EOF

    echo -e "${GREEN}---> Plank dock configured and set to autostart.${NC}"
}

# ==========================================
# 5. UX & WORKFLOW OPTIMIZATIONS
# ==========================================
apply_ux() {
    echo -e "${BLUE}>>> Phase 5: UX & workflow optimizations${NC}"

    gsettings set org.cinnamon alttab-switcher-style 'icons'
    gsettings set org.cinnamon alttab-switcher-delay 0
    gsettings set org.cinnamon.muffin edge-tiling true
    gsettings set org.cinnamon.muffin workspace-cycle true

    echo -e "${GREEN}---> Alt-Tab, edge tiling, and workspace cycling configured.${NC}"
}

# ==========================================
# 6. SCREEN RECORDER KEYBINDING (PEEK)
# ==========================================
setup_peek_keybinding() {
    echo -e "${BLUE}>>> Phase 6: Screen recorder keybinding (Peek)${NC}"

    KEYBINDING_ID="custom99"
    CURRENT_LIST=$(gsettings get org.cinnamon.desktop.keybindings custom-list 2>/dev/null | sed 's/@as //')

    python3 -c "
import ast, sys, subprocess
raw = sys.argv[1]
try:
    lst = ast.literal_eval(raw) if raw.strip() not in ('', '[]') else []
except (ValueError, SyntaxError):
    lst = []
clean = [sys.argv[2]]
for item in lst:
    if item not in ('mac-shot', sys.argv[2]):
        clean.append(item)
subprocess.run(
    ['gsettings', 'set', 'org.cinnamon.desktop.keybindings', 'custom-list', str(clean)],
    check=True,
)
" "$CURRENT_LIST" "$KEYBINDING_ID"

    DCONF_PATH="org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/${KEYBINDING_ID}/"
    gsettings set "$DCONF_PATH" name 'Screen Recorder (Peek)'
    gsettings set "$DCONF_PATH" command 'peek'
    gsettings set "$DCONF_PATH" binding "['<Super><Shift>5']"

    echo -e "${GREEN}---> Super+Shift+5 mapped to Peek.${NC}"
}

# ==========================================
# 7. FINALIZE
# ==========================================
finalize() {
    echo -e "${BLUE}>>> Flushing font caches and restarting window manager...${NC}"
    fc-cache -f

    # Restart Cinnamon — try D-Bus eval first, fall back to cinnamon --replace
    if ! busctl --user call org.Cinnamon /org/Cinnamon org.Cinnamon Eval s 'Main.replaceMain()' &>/dev/null; then
        echo -e "${YELLOW}---> D-Bus restart failed (Cinnamon 6.x+). Falling back to cinnamon --replace.${NC}"
        nohup cinnamon --replace &>/dev/null &
    fi
}

main() {
    install_deps
    apply_theme
    apply_behavior
    setup_dock
    apply_ux
    setup_peek_keybinding
    finalize

    echo -e "\n${GREEN}=====================================================${NC}"
    echo -e "${GREEN}     Desktop bootstrap complete.${NC}"
    echo -e "${GREEN}=====================================================${NC}"
    echo ""
}

main
