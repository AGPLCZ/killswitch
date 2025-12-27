#!/bin/bash

# --- KONFIGURACE SOUBORŮ ---
CLI_SOURCE="killswitch-manager.sh"
GUI_SOURCE="killswitch-gui.py"

# Cílové destinace
CLI_DEST="/usr/local/bin/killswitch"
GUI_DIR="/opt/killswitch-gui"
GUI_DEST="$GUI_DIR/manager.py"
# Nový pomocný spouštěč pro GUI
GUI_LAUNCHER="/usr/local/bin/killswitch-gui-start"

# Ikony v menu
DESKTOP_CLI="/usr/share/applications/killswitch-cli.desktop"
DESKTOP_GUI="/usr/share/applications/killswitch-gui.desktop"

# Cesty pro odinstalaci
RULE_DIR="/etc/udev/rules.d"
ROOT_KILL="/root/killswitch.sh"

# Barvy
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m'

# Kontrola ROOT
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Spusť tento instalátor jako root (sudo ./install.sh)${NC}"
  exit 1
fi

function pause() {
  echo ""
  read -p "Stiskni Enter pro pokračování..."
}

function check_dependencies() {
    echo "📦 Kontrola závislostí..."
    # Kontrola Python Tkinter
    if ! python3 -c "import tkinter" &> /dev/null; then
        echo -e "${YELLOW}Doinstalovávám python3-tk...${NC}"
        apt-get update -qq
        apt-get install -y python3-tk
    fi
    # Kontrola xhost (potřeba pro GUI pod rootem)
    if ! command -v xhost &> /dev/null; then
        echo -e "${YELLOW}Doinstalovávám x11-xserver-utils (xhost)...${NC}"
        apt-get install -y x11-xserver-utils
    fi
    echo -e "${GREEN}Závislosti jsou v pořádku.${NC}"
}

function install_manager() {
  echo ""
  echo -e "${GREEN}➡️  INSTALACE KILLSWITCH MANAGERU${NC}"

  if [ ! -f "$CLI_SOURCE" ] || [ ! -f "$GUI_SOURCE" ]; then
      echo -e "${RED}❌ Chyba: Nenalezeny zdrojové soubory (killswitch-manager.sh nebo killswitch-gui.py).${NC}"
      pause
      return
  fi

  check_dependencies

  # 1. Instalace CLI
  echo "📁 Instaluji CLI..."
  cp "$CLI_SOURCE" "$CLI_DEST"
  chmod +x "$CLI_DEST"

  # 2. Instalace GUI Scriptu
  echo "📁 Instaluji GUI..."
  mkdir -p "$GUI_DIR"
  cp "$GUI_SOURCE" "$GUI_DEST"
  chmod +x "$GUI_DEST"

  # 3. Vytvoření SPOUŠTĚČE (Wrapperu) pro GUI
  # Toto řeší problém s pádem aplikace - nastaví xhost a cesty
  echo "⚙️  Vytvářím bezpečný spouštěč..."
  cat <<EOF > "$GUI_LAUNCHER"
#!/bin/bash
# Povolit rootovi přístup k X serveru (obrazovce)
xhost +si:localuser:root > /dev/null 2>&1
# Spustit aplikaci s předáním grafického prostředí
pkexec env DISPLAY=\$DISPLAY XAUTHORITY=\$XAUTHORITY /usr/bin/python3 $GUI_DEST
EOF
  chmod +x "$GUI_LAUNCHER"

  # 4. Ikony
  echo ""
  read -p "Vytvořit ikony v menu? [y/N]: " desktop_confirm
  if [[ "$desktop_confirm" == "y" || "$desktop_confirm" == "Y" ]]; then
      
      # Ikona terminálu
      cat <<EOF > "$DESKTOP_CLI"
[Desktop Entry]
Name=Killswitch Console
Comment=Správa USB ochrany (Terminál)
Exec=sudo killswitch
Icon=utilities-terminal
Terminal=true
Type=Application
Categories=Utility;System;
EOF

      # Ikona GUI - nyní volá náš spouštěč
      cat <<EOF > "$DESKTOP_GUI"
[Desktop Entry]
Name=Killswitch Manager
Comment=Správa USB ochrany (GUI)
Exec=$GUI_LAUNCHER
Icon=security-high
Terminal=false
Type=Application
Categories=Utility;System;Settings;
EOF

      echo "🖱️  Ikony vytvořeny."
  fi

  echo ""
  echo -e "${GREEN}✅ Hotovo.${NC}"
  echo "Nyní můžeš aplikaci spustit z menu."
  pause
}

function uninstall_manager() {
  echo ""
  echo -e "${RED}⚠️  ODINSTALACE${NC}"

  rm -f "$CLI_DEST" "$GUI_LAUNCHER"
  rm -rf "$GUI_DIR"
  rm -f "$DESKTOP_CLI" "$DESKTOP_GUI"
  
  # Smazání pravidel
  rm -f "$RULE_DIR"/85-killswitch-*.rules
  udevadm control --reload-rules
  
  if [ -f "$ROOT_KILL" ]; then
      rm "$ROOT_KILL"
      echo "🗑️  Smazán vypínací skript."
  fi

  echo -e "${GREEN}✅ Odinstalováno.${NC}"
  pause
}

# === MENU ===
while true; do
  clear
  echo -e "${GREEN}Killswitch Installer${NC}"
  echo "1) Instalovat / Opravit instalaci"
  echo "2) Odinstalovat"
  echo "3) Konec"
  echo ""
  read -p "Volba: " opt

  case "$opt" in
    1) install_manager ;;
    2) uninstall_manager ;;
    3) exit 0 ;;
    *) echo "Neplatná volba" ;;
  esac
done