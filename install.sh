#!/bin/bash

# --- 0. OKAMŽITÁ KONTROLA ROOT PRÁV ---
# Musí být hned nahoře, aby se script neukončil až po výběru jazyka
if [ "$EUID" -ne 0 ]; then
  echo "❌ CRITICAL ERROR: Please run as root!"
  echo "❌ CHYBA: Spusťte prosím jako root!"
  echo ""
  echo "Use/Použijte: sudo ./install.sh"
  exit 1
fi

# --- KONFIGURACE SOUBORŮ ---
CLI_SOURCE="killswitch-manager.sh"
GUI_SOURCE="killswitch-gui.py"

# Cílové destinace
CLI_DEST="/usr/local/bin/killswitch"
GUI_DIR="/opt/killswitch-gui"
GUI_DEST="$GUI_DIR/manager.py"
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

# ==========================================
#  LOKALIZACE / LANGUAGE SETTINGS
# ==========================================

clear
echo "Select installation language / Vyberte jazyk instalace:"
echo "1) English"
echo "2) Čeština"
echo ""
read -p "> " lang_opt

# Defaultně EN, pokud zvolí 2 tak CS
LANG_MODE="en"
if [ "$lang_opt" == "2" ]; then
    LANG_MODE="cs"
fi

# Definice textů
if [ "$LANG_MODE" == "cs" ]; then
    # --- CZECH ---
    TXT_PRESS_ENTER="Stiskni Enter pro pokračování..."
    TXT_CHECK_DEPS="📦 Kontrola závislostí..."
    TXT_INSTALLING_TK="Doinstalovávám python3-tk..."
    TXT_INSTALLING_XHOST="Doinstalovávám x11-xserver-utils (xhost)..."
    TXT_DEPS_OK="Závislosti jsou v pořádku."
    TXT_INSTALL_TITLE="➡️  INSTALACE KILLSWITCH MANAGERU"
    TXT_ERR_FILES="❌ Chyba: Nenalezeny zdrojové soubory (killswitch-manager.sh nebo killswitch-gui.py)."
    TXT_INST_CLI="📁 Instaluji CLI..."
    TXT_INST_GUI="📁 Instaluji GUI..."
    TXT_CREATE_LAUNCHER="⚙️  Vytvářím bezpečný spouštěč..."
    TXT_CREATE_ICONS="Vytvořit ikony v menu? [y/N]: "
    TXT_ICONS_CREATED="🖱️  Ikony vytvořeny."
    TXT_DONE="✅ Hotovo."
    TXT_RUN_HINT="Nyní můžeš aplikaci spustit z menu."
    
    TXT_UNINSTALL_TITLE="⚠️  ODINSTALACE"
    TXT_DEL_SCRIPT="🗑️  Smazán vypínací skript."
    TXT_UNINSTALLED="✅ Odinstalováno."
    
    TXT_MENU_TITLE="Killswitch Installer"
    TXT_OPT_1="1) Instalovat / Opravit instalaci"
    TXT_OPT_2="2) Odinstalovat"
    TXT_OPT_3="3) Konec"
    TXT_OPT_SELECT="Volba: "
    TXT_INVALID="Neplatná volba"
else
    # --- ENGLISH ---
    TXT_PRESS_ENTER="Press Enter to continue..."
    TXT_CHECK_DEPS="📦 Checking dependencies..."
    TXT_INSTALLING_TK="Installing python3-tk..."
    TXT_INSTALLING_XHOST="Installing x11-xserver-utils (xhost)..."
    TXT_DEPS_OK="Dependencies are OK."
    TXT_INSTALL_TITLE="➡️  INSTALLING KILLSWITCH MANAGER"
    TXT_ERR_FILES="❌ Error: Source files not found (killswitch-manager.sh or killswitch-gui.py)."
    TXT_INST_CLI="📁 Installing CLI..."
    TXT_INST_GUI="📁 Installing GUI..."
    TXT_CREATE_LAUNCHER="⚙️  Creating safe launcher..."
    TXT_CREATE_ICONS="Create menu icons? [y/N]: "
    TXT_ICONS_CREATED="🖱️  Icons created."
    TXT_DONE="✅ Done."
    TXT_RUN_HINT="You can now run the app from the system menu."
    
    TXT_UNINSTALL_TITLE="⚠️  UNINSTALLATION"
    TXT_DEL_SCRIPT="🗑️  Shutdown script deleted."
    TXT_UNINSTALLED="✅ Uninstalled."
    
    TXT_MENU_TITLE="Killswitch Installer"
    TXT_OPT_1="1) Install / Repair installation"
    TXT_OPT_2="2) Uninstall"
    TXT_OPT_3="3) Exit"
    TXT_OPT_SELECT="Choice: "
    TXT_INVALID="Invalid choice"
fi

function pause() {
  echo ""
  read -p "$TXT_PRESS_ENTER"
}

function check_dependencies() {
    echo "$TXT_CHECK_DEPS"
    if ! python3 -c "import tkinter" &> /dev/null; then
        echo -e "${YELLOW}$TXT_INSTALLING_TK${NC}"
        apt-get update -qq
        apt-get install -y python3-tk
    fi
    if ! command -v xhost &> /dev/null; then
        echo -e "${YELLOW}$TXT_INSTALLING_XHOST${NC}"
        apt-get install -y x11-xserver-utils
    fi
    echo -e "${GREEN}$TXT_DEPS_OK${NC}"
}

function install_manager() {
  echo ""
  echo -e "${GREEN}$TXT_INSTALL_TITLE${NC}"

  if [ ! -f "$CLI_SOURCE" ] || [ ! -f "$GUI_SOURCE" ]; then
      echo -e "${RED}$TXT_ERR_FILES${NC}"
      pause
      return
  fi

  check_dependencies

  echo "$TXT_INST_CLI"
  cp "$CLI_SOURCE" "$CLI_DEST"
  chmod +x "$CLI_DEST"

  echo "$TXT_INST_GUI"
  mkdir -p "$GUI_DIR"
  cp "$GUI_SOURCE" "$GUI_DEST"
  chmod +x "$GUI_DEST"

  echo "$TXT_CREATE_LAUNCHER"
  cat <<EOF > "$GUI_LAUNCHER"
#!/bin/bash
xhost +si:localuser:root > /dev/null 2>&1
pkexec env DISPLAY=\$DISPLAY XAUTHORITY=\$XAUTHORITY /usr/bin/python3 $GUI_DEST
EOF
  chmod +x "$GUI_LAUNCHER"

  echo ""
  read -p "$TXT_CREATE_ICONS" desktop_confirm
  if [[ "$desktop_confirm" == "y" || "$desktop_confirm" == "Y" ]]; then
      
      cat <<EOF > "$DESKTOP_CLI"
[Desktop Entry]
Name=Killswitch Console
Name[cs]=Killswitch Konzole
Comment=USB Protection Management (Terminal)
Comment[cs]=Správa USB ochrany (Terminál)
Exec=sudo killswitch
Icon=utilities-terminal
Terminal=true
Type=Application
Categories=Utility;System;
EOF

      cat <<EOF > "$DESKTOP_GUI"
[Desktop Entry]
Name=Killswitch Manager
Name[cs]=Killswitch Manager
Comment=USB Protection Management (GUI)
Comment[cs]=Správa USB ochrany (GUI)
Exec=$GUI_LAUNCHER
Icon=security-high
Terminal=false
Type=Application
Categories=Utility;System;Settings;
EOF

      echo "$TXT_ICONS_CREATED"
  fi

  echo ""
  echo -e "${GREEN}$TXT_DONE${NC}"
  echo "$TXT_RUN_HINT"
  pause
}

function uninstall_manager() {
  echo ""
  echo -e "${RED}$TXT_UNINSTALL_TITLE${NC}"

  rm -f "$CLI_DEST" "$GUI_LAUNCHER"
  rm -rf "$GUI_DIR"
  rm -f "$DESKTOP_CLI" "$DESKTOP_GUI"
  rm -f "$RULE_DIR"/85-killswitch-*.rules
  udevadm control --reload-rules
  
  if [ -f "$ROOT_KILL" ]; then
      rm "$ROOT_KILL"
      echo "$TXT_DEL_SCRIPT"
  fi

  echo -e "${GREEN}$TXT_UNINSTALLED${NC}"
  pause
}

# === MENU ===
while true; do
  clear
  echo -e "${GREEN}$TXT_MENU_TITLE${NC}"
  echo "$TXT_OPT_1"
  echo "$TXT_OPT_2"
  echo "$TXT_OPT_3"
  echo ""
  read -p "$TXT_OPT_SELECT" opt

  case "$opt" in
    1) install_manager ;;
    2) uninstall_manager ;;
    3) exit 0 ;;
    *) echo "$TXT_INVALID" ;;
  esac
done