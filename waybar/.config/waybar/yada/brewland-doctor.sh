#!/bin/bash

# brewland diagnostics
# checks dependencies, configs, and running services

RED='\033[0;31m'
GRN='\033[0;32m'
YLW='\033[0;33m'
BLU='\033[0;34m'
RST='\033[0m'

try_fix() {
    echo -e "\n${BLU}:: attempting to fix issues...${RST}"
    
    for pkg in "${CHECK_PKGS[@]}"; do
        if ! pacman -Qi "$pkg" &> /dev/null; then
            echo -e "${YLW}installing $pkg...${RST}"
            yay -S --noconfirm "$pkg"
        fi
    done
    
    for svc in "${SERVICES[@]}"; do
        if ! pgrep -x "$svc" &> /dev/null; then
            echo -e "${YLW}starting $svc...${RST}"
            if [[ "$svc" == "awww-daemon" ]]; then
                awww-daemon & disown
            else
                $svc & disown
            fi
            sleep 1
        fi
    done
    
    if ! pgrep -f "xdg-desktop-portal-hyprland" &> /dev/null; then
        echo -e "${YLW}restarting portal...${RST}"
        /usr/lib/xdg-desktop-portal-hyprland & disown
    fi
    
    echo -e "${GRN}applied fixes. run doctor again to verify.${RST}"
}

echo -e "${BLU}:: running brewland doctor...${RST}"

# check core pkgs
CHECK_PKGS=("hyprland" "waybar" "rofi" "swaync" "kitty" "awww" "fastfetch")
MISSING=0

echo -e "\n${YLW}[ 1/4 ] core dependencies${RST}"
for pkg in "${CHECK_PKGS[@]}"; do
    if pacman -Qi "$pkg" &> /dev/null; then
        echo -e "  [ ${GRN}OK${RST} ] $pkg"
    else
        echo -e "  [ ${RED}!!${RST} ] $pkg missing"
        MISSING=$((MISSING + 1))
    fi
done

# check aur helper
echo -e "\n${YLW}[ 2/4 ] aur helper${RST}"
if command -v yay &> /dev/null; then
    echo -e "  [ ${GRN}OK${RST} ] yay is installed"
else
    echo -e "  [ ${RED}!!${RST} ] yay missing"
    MISSING=$((MISSING + 1))
fi

# verify dotfiles are linked
echo -e "\n${YLW}[ 3/4 ] config links${RST}"
DOTFILES=("hypr" "kitty" "rofi" "swaync" "waybar")
for folder in "${DOTFILES[@]}"; do
    target="$HOME/.config/$folder"
    if [[ -d "$target" || -L "$target" ]]; then
        if [[ -L "$target" ]]; then
            echo -e "  [ ${GRN}OK${RST} ] $folder (symlinked)"
        else
            echo -e "  [ ${YLW}OK${RST} ] $folder (standard)"
        fi
    else
        echo -e "  [ ${RED}!!${RST} ] $folder missing from ~/.config"
        MISSING=$((MISSING + 1))
    fi
done

# verify services
echo -e "\n${YLW}[ 4/4 ] active services${RST}"
SERVICES=("waybar" "awww-daemon" "hypridle" "swaync")
for svc in "${SERVICES[@]}"; do
    if pgrep -x "$svc" &> /dev/null; then
        echo -e "  [ ${GRN}OK${RST} ] $svc is running"
    else
        echo -e "  [ ${YLW}!!${RST} ] $svc not running"
        MISSING=$((MISSING + 1))
    fi
done

if pgrep -f "xdg-desktop-portal-hyprland" &> /dev/null; then
    echo -e "  [ ${GRN}OK${RST} ] portal is running"
else
    echo -e "  [ ${RED}!!${RST} ] portal not running"
    MISSING=$((MISSING + 1))
fi

echo -e "\n--------------------------------------------------"
if [[ $MISSING -eq 0 ]]; then
    echo -e "${GRN}brewland is healthy!${RST}"
else
    echo -e "${RED}found $MISSING issues.${RST}"
    read -p "auto-fix? (y/n): " choice
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        try_fix
    else
        echo -e "${YLW}run install.sh manually to fix.${RST}"
    fi
fi
echo "--------------------------------------------------"
