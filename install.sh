#!/bin/bash

MANAGER_FILE="killswitch-manager.sh"
INSTALL_PATH="/usr/local/bin/killswitch"
DESKTOP_FILE="$HOME/.local/share/applications/killswitch.desktop"
SHORTCUT_SCRIPT="$HOME/kill.sh"
RULE_DIR="/etc/udev/rules.d"
ROOT_KILL="/root/killswitch.sh"

YELLOW='\033[1;33m'
GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m'

function pause() {
  echo ""
  read -p "Stiskni Enter pro pokračování..."
}

function install_manager() {
  echo ""
  echo "➡️ Instalace Killswitch Manageru"

  if [ ! -f "$MANAGER_FILE" ]; then
      echo -e "${RED}❌ Soubor $MANAGER_FILE nebyl nalezen. Ujisti se, že jsi ve správném adresáři.${NC}"
      pause
      return
  fi

  echo "📁 Kopíruji do $INSTALL_PATH"
  sudo cp "$MANAGER_FILE" "$INSTALL_PATH"
  sudo chmod +x "$INSTALL_PATH"

  echo ""
  read -p "Chceš vytvořit ikonu v menu (killswitch.desktop)? [y/N]: " desktop_confirm
  if [[ "$desktop_confirm" == "y" || "$desktop_confirm" == "Y" ]]; then
      mkdir -p "$(dirname "$DESKTOP_FILE")"
      cat <<EOF > "$DESKTOP_FILE"
[Desktop Entry]
Name=Killswitch Manager
Exec=sudo killswitch
Icon=utilities-terminal
Terminal=true
Type=Application
Categories=Utility;
EOF
      chmod +x "$DESKTOP_FILE"
      echo "🖱️ Ikona byla vytvořena."
  fi

  echo ""
  echo -e "${GREEN}✅ Instalace dokončena.${NC}"
  echo ""
  echo -e "${YELLOW}Spusť správce tímto příkazem:${NC}"
  echo "   sudo killswitch"
  echo ""
  echo "🖱️ Nebo najdeš aplikaci v nabídce pod názvem 'Killswitch Manager'."

  pause
}

function uninstall_manager() {
  echo ""
  echo "⚠️ Odinstalace Killswitch Manageru"

  if [ -f "$INSTALL_PATH" ]; then
    sudo rm "$INSTALL_PATH"
    echo "🗑️ Odebrán $INSTALL_PATH"
  fi

  if [ -f "$DESKTOP_FILE" ]; then
    rm "$DESKTOP_FILE"
    echo "🗑️ Odebrána ikona z menu"
  fi

  if [ -f "$SHORTCUT_SCRIPT" ]; then
    read -p "Smazat i klávesovou zkratku ~/kill.sh? [y/N]: " del_shortcut
    if [[ "$del_shortcut" == "y" || "$del_shortcut" == "Y" ]]; then
      rm "$SHORTCUT_SCRIPT"
      echo "🗑️ Smazán $SHORTCUT_SCRIPT"
    fi
  fi

  echo ""
  echo "➡️ Deaktivuji všechna pravidla USB killswitch..."
  sudo rm -f "$RULE_DIR"/85-killswitch-*.rules
  echo "🗑️ Smazána všechna pravidla v $RULE_DIR"
  sudo udevadm control --reload-rules

  if [ -f "$ROOT_KILL" ]; then
    read -p "Smazat i /root/killswitch.sh? [y/N]: " del_root
    if [[ "$del_root" == "y" || "$del_root" == "Y" ]]; then
      sudo rm "$ROOT_KILL"
      echo "🗑️ Smazán $ROOT_KILL"
    fi
  fi

  echo ""
  echo -e "${GREEN}✅ Killswitch Manager a všechna zařízení byly deaktivovány a odstraněny.${NC}"
  pause
}


# === MENU ===
while true; do
  clear
  echo -e "${GREEN}Killswitch Manager – Instalátor / Odinstalátor${NC}"
  echo ""
  echo "1) Instalovat Killswitch Manager"
  echo "2) Odinstalovat Killswitch Manager"
  echo "3) Ukončit"
  echo ""
  read -p "Zadej volbu: " opt

  case "$opt" in
    1) install_manager ;;
    2) uninstall_manager ;;
    3) echo "Ukončuji..."; exit 0 ;;
    *) echo -e "${RED}Neplatná volba${NC}"; pause ;;
  esac
done

