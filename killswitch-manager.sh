#!/bin/bash

RULE_DIR="/etc/udev/rules.d"
SCRIPT_PATH="/root/killswitch.sh"
LOG_PATH="/root/usbkill.log"
SHORTCUT_SCRIPT="$HOME/kill.sh"

YELLOW='\033[1;33m'
GREEN='\033[1;32m'
RED='\033[1;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# ==========================================
#  LOCALIZATION / JAZYKY
# ==========================================

# 1. Automatická detekce jazyka systému (pokud obsahuje "cs" nebo "CZ", nastavíme cs, jinak en)
if [[ "$LANG" == *"cs"* || "$LANG" == *"CZ"* ]]; then
    CURRENT_LANG="cs"
else
    CURRENT_LANG="en"
fi

# 2. Definice textů (Slovník v Bashi simulujeme funkcí)
function set_language() {
    local mode=$1
    
    if [ "$mode" == "cs" ]; then
        # --- CZECH ---
        TXT_TITLE="            KILL-SWITCH            "
        TXT_MENU_1="1) Přidat nové USB zařízení jako killswitch (vypnutí při ODPOJENÍ)"
        TXT_MENU_2="2) Přidat 'PAST' zařízení (vypnutí při ZAPOJENÍ)"
        TXT_MENU_3="3) Zobrazit aktivní killswitch pravidla"
        TXT_MENU_4="4) Odstranit jedno zařízení"
        TXT_MENU_5="5) Hromadně deaktivovat všechna zařízení"
        TXT_MENU_6="6) Vytvořit killswitch na klávesovou zkratku"
        TXT_MENU_7="7) Odstranit klávesovou zkratku"
        TXT_MENU_8="8) Znovu načíst pravidla"
        TXT_MENU_9="9) Konec"
        TXT_SELECT_ACTION="Vyber akci: "
        
        TXT_CREATING_SCRIPT="Vytvářím /root/killswitch.sh..."
        TXT_SCANNING="Prohledávám a filtruji zařízení..."
        TXT_NO_REMOVABLE="Nenalezena žádná VÝMĚNNÁ (removable) USB zařízení."
        TXT_TRAP_MODE_WARN="REŽIM PAST: PC se vypne při PŘIPOJENÍ vybraného zařízení!"
        TXT_KILL_MODE_INFO="REŽIM KILLSWITCH: PC se vypne při ODPOJENÍ vybraného zařízení."
        TXT_ENTER_DEV_NUM="Zadej číslo zařízení: "
        TXT_INVALID_CHOICE="Neplatná volba."
        TXT_ERR_ID="Chyba: Nepodařilo se rozpoznat ID zařízení."
        TXT_FOUND_SN="Nalezeno SN: "
        TXT_CREATE_KILL_RULE="Vytvářím pravidlo pro odpojení (Ignoruji SN pro maximální spolehlivost)..."
        TXT_PREVIEW="--- NÁHLED PRAVIDLA ---"
        TXT_DEV_ID="ID Zařízení: "
        TXT_FILE="Soubor: "
        TXT_CONTENT="Obsah:"
        TXT_RULE_SAVED="Pravidlo uloženo."
        TXT_TRAP_DONE_WARN="VAROVÁNÍ: PC se vypne, jakmile toto zařízení připojíš."
        TXT_KILL_DONE_INFO="Hotovo. Zkus zařízení vytáhnout."
        
        TXT_ACTIVE_RULES="Aktivní killswitch pravidla:"
        TXT_NO_RULES="❌ Nejsou přidána žádná pravidla."
        TXT_DELETE_RULE="Smazat pravidlo:"
        TXT_DELETED="Smazáno."
        TXT_ALL_DELETED="Vše smazáno."
        
        TXT_AUTO_SHORTCUT="Automatické nastavení klávesové zkratky..."
        TXT_ERR_USER="Chyba: Nelze detekovat reálného uživatele."
        TXT_SCRIPT_CREATED="1. Skript vytvořen:"
        TXT_SETTING_PERMS="Nastavuji práva v"
        TXT_PERMS_SET="2. Práva nastavena (nebude vyžadováno heslo)."
        TXT_ERR_SUDOERS="Chyba při kontrole sudoers. Mažu vadný soubor."
        TXT_SETTING_GNOME="3. Nastavuji systémovou zkratku (Ctrl+Enter)..."
        TXT_ERR_DBUS="Varování: Nelze najít grafickou relaci uživatele (DBUS). Zkratku nelze nastavit automaticky."
        TXT_DONE_SHORTCUT="✅ Hotovo! Nyní můžeš stisknout Ctrl + Enter pro vypnutí PC."
        
        TXT_REMOVING_SHORTCUT="Odstraňuji klávesovou zkratku a soubory..."
        TXT_DELETED_SCRIPT="Smazán skript:"
        TXT_SCRIPT_NOT_FOUND="Skript nenalezen (již smazán?)"
        TXT_REMOVED_SUDOERS="Odebrána práva sudoers:"
        TXT_SUDOERS_NOT_FOUND="Sudoers soubor nenalezen."
        TXT_DELETING_GNOME="Mažu zkratku ze systému..."
        TXT_SHORTCUT_REMOVED="✅ Zkratka byla úspěšně odstraněna ze systému."
        TXT_RELOADED="Pravidla znovu načtena."
        TXT_EXITING="Ukončuji..."
    else
        # --- ENGLISH (Default) ---
        TXT_TITLE="            KILL-SWITCH            "
        TXT_MENU_1="1) Add new USB device as Killswitch (Shutdown on REMOVAL)"
        TXT_MENU_2="2) Add 'TRAP' device (Shutdown on INSERTION)"
        TXT_MENU_3="3) Show active rules"
        TXT_MENU_4="4) Delete one device rule"
        TXT_MENU_5="5) Deactivate ALL devices"
        TXT_MENU_6="6) Create keyboard shortcut (Panic Button)"
        TXT_MENU_7="7) Remove keyboard shortcut"
        TXT_MENU_8="8) Reload rules"
        TXT_MENU_9="9) Exit"
        TXT_SELECT_ACTION="Select action: "
        
        TXT_CREATING_SCRIPT="Creating /root/killswitch.sh..."
        TXT_SCANNING="Scanning and filtering devices..."
        TXT_NO_REMOVABLE="No REMOVABLE USB devices found."
        TXT_TRAP_MODE_WARN="TRAP MODE: PC will shutdown upon INSERTION of selected device!"
        TXT_KILL_MODE_INFO="KILLSWITCH MODE: PC will shutdown upon REMOVAL of selected device."
        TXT_ENTER_DEV_NUM="Enter device number: "
        TXT_INVALID_CHOICE="Invalid choice."
        TXT_ERR_ID="Error: Could not identify device ID."
        TXT_FOUND_SN="Found SN: "
        TXT_CREATE_KILL_RULE="Creating removal rule (Ignoring SN for maximum reliability)..."
        TXT_PREVIEW="--- RULE PREVIEW ---"
        TXT_DEV_ID="Device ID: "
        TXT_FILE="File: "
        TXT_CONTENT="Content:"
        TXT_RULE_SAVED="Rule saved."
        TXT_TRAP_DONE_WARN="WARNING: PC will shutdown as soon as you connect this device."
        TXT_KILL_DONE_INFO="Done. Try removing the device."
        
        TXT_ACTIVE_RULES="Active Killswitch Rules:"
        TXT_NO_RULES="❌ No rules added."
        TXT_DELETE_RULE="Delete rule:"
        TXT_DELETED="Deleted."
        TXT_ALL_DELETED="All rules deleted."
        
        TXT_AUTO_SHORTCUT="Setting up keyboard shortcut automatically..."
        TXT_ERR_USER="Error: Cannot detect real user."
        TXT_SCRIPT_CREATED="1. Script created:"
        TXT_SETTING_PERMS="Setting permissions in"
        TXT_PERMS_SET="2. Permissions set (password will not be required)."
        TXT_ERR_SUDOERS="Error checking sudoers. Deleting faulty file."
        TXT_SETTING_GNOME="3. Setting system shortcut (Ctrl+Enter)..."
        TXT_ERR_DBUS="Warning: Cannot find user graphical session (DBUS). Cannot set shortcut automatically."
        TXT_DONE_SHORTCUT="✅ Done! You can now press Ctrl + Enter to shutdown PC."
        
        TXT_REMOVING_SHORTCUT="Removing keyboard shortcut and files..."
        TXT_DELETED_SCRIPT="Deleted script:"
        TXT_SCRIPT_NOT_FOUND="Script not found (already deleted?)"
        TXT_REMOVED_SUDOERS="Removed sudoers rights:"
        TXT_SUDOERS_NOT_FOUND="Sudoers file not found."
        TXT_DELETING_GNOME="Deleting shortcut from system..."
        TXT_SHORTCUT_REMOVED="✅ Shortcut successfully removed from system."
        TXT_RELOADED="Rules reloaded."
        TXT_EXITING="Exiting..."
    fi
}

# Inicializace jazyka
set_language "$CURRENT_LANG"

# ==========================================
#  HLAVNÍ KÓD (Logika beze změn)
# ==========================================

# Pole pro ukládání filtrovaných zařízení
filtered_devices=()

function show_menu() {
    echo ""
    echo -e "${GREEN}═══════════════════════════════════${NC}"
    echo -e "${GREEN}$TXT_TITLE${NC}"
    echo ""
    echo "$TXT_MENU_1"
    echo "$TXT_MENU_2"
    echo "$TXT_MENU_3"
    echo "$TXT_MENU_4"
    echo "$TXT_MENU_5"
    echo "$TXT_MENU_6"
    echo "$TXT_MENU_7"
    echo "$TXT_MENU_8"
    echo "$TXT_MENU_9"
    echo ""
    read -p "$TXT_SELECT_ACTION" choice
}

function create_shutdown_script() {
    if [ ! -f "$SCRIPT_PATH" ]; then
        echo "$TXT_CREATING_SCRIPT"
    fi
    # --no-block je kritické pro udev
    cat <<EOF | sudo tee "$SCRIPT_PATH" > /dev/null
#!/bin/bash
echo "\$(date) - KILLSWITCH SPUŠTĚN" >> "$LOG_PATH"
/bin/systemctl poweroff -i --no-block
EOF
    sudo chmod +x "$SCRIPT_PATH"
}

# Funkce pro načtení a filtraci zařízení (pouze removable)
function load_and_filter_devices() {
    filtered_devices=()
    echo -e "${YELLOW}$TXT_SCANNING${NC}"
    
    mapfile -t all_usb < <(lsusb | grep -v "Linux Foundation")

    for line in "${all_usb[@]}"; do
        bus=$(echo "$line" | awk '{print $2}')
        dev=$(echo "$line" | awk '{print $4}' | tr -d :)
        dev_path="/dev/bus/usb/$bus/$dev"
        sys_path=$(udevadm info -q path -n "$dev_path" 2>/dev/null)
        
        is_removable="unknown"
        if [ -f "/sys$sys_path/removable" ]; then
             state=$(cat "/sys$sys_path/removable")
             if [ "$state" == "fixed" ]; then
                is_removable="fixed"
             else
                is_removable="removable"
             fi
        fi

        if [ "$is_removable" != "fixed" ]; then
             filtered_devices+=("$line")
        fi
    done
}

function add_device_logic() {
    local mode=$1 
    
    load_and_filter_devices

    if [ ${#filtered_devices[@]} -eq 0 ]; then
        echo -e "${RED}$TXT_NO_REMOVABLE${NC}"
        return
    fi

    echo ""
    if [ "$mode" == "trap" ]; then
        echo -e "${RED}$TXT_TRAP_MODE_WARN${NC}"
    else
        echo "$TXT_KILL_MODE_INFO"
    fi

    for i in "${!filtered_devices[@]}"; do
        echo "[$((i+1))] ${filtered_devices[$i]}"
    done

    echo ""
    read -p "$TXT_ENTER_DEV_NUM" index_input
    index=$((index_input - 1))

    if ! [[ "$index_input" =~ ^[0-9]+$ ]] || [ "$index" -lt 0 ] || [ "$index" -ge "${#filtered_devices[@]}" ]; then
        echo -e "${RED}$TXT_INVALID_CHOICE${NC}"
        return
    fi

    raw_line="${filtered_devices[$index]}"
    selected_line=$(echo "$raw_line" | sed 's/\x1b\[[0-9;]*m//g')
    
    if [[ $selected_line =~ ID\ ([0-9a-fA-F]+):([0-9a-fA-F]+) ]]; then
        vid="${BASH_REMATCH[1]}"
        pid="${BASH_REMATCH[2]}"
    else
        echo -e "${RED}$TXT_ERR_ID${NC}"
        return
    fi

    # Získání správného Serial Number (pouze pro PAST)
    bus=$(echo "$selected_line" | awk '{print $2}')
    dev=$(echo "$selected_line" | awk '{print $4}' | tr -d :)
    dev_path="/dev/bus/usb/$bus/$dev"
    real_serial=$(udevadm info --query=property --name="$dev_path" | grep "ID_SERIAL_SHORT=" | cut -d'=' -f2)
    
    create_shutdown_script
    
    rule_name="85-killswitch-${vid}-${pid}.rules"
    if [ "$mode" == "trap" ]; then
        rule_name="85-killswitch-trap-${vid}-${pid}.rules"
    fi
    rule_file="$RULE_DIR/$rule_name"
    rule_content=""
    
    if [ "$mode" == "trap" ]; then
        # === PAST (ADD) ===
        serial_part=""
        if [ ! -z "$real_serial" ]; then
            echo -e "${GREEN}$TXT_FOUND_SN$real_serial${NC}"
            serial_part=", ATTRS{serial}==\"$real_serial\""
        fi
        rule_content="ACTION==\"add\", SUBSYSTEM==\"usb\", ATTRS{idVendor}==\"$vid\", ATTRS{idProduct}==\"$pid\"$serial_part, RUN+=\"$SCRIPT_PATH\""
    
    else
        # === KILLSWITCH (REMOVE) ===
        echo -e "${YELLOW}$TXT_CREATE_KILL_RULE${NC}"
        rule_content="ACTION==\"remove\", ENV{PRODUCT}==\"$vid/$pid/*\", RUN+=\"$SCRIPT_PATH\""
    fi

    echo ""
    echo -e "${YELLOW}$TXT_PREVIEW${NC}"
    echo "$TXT_DEV_ID$vid:$pid"
    echo "$TXT_FILE$rule_file"
    echo -e "$TXT_CONTENT\n${BLUE}$rule_content${NC}"
    echo -e "${YELLOW}-----------------------${NC}"
    
    echo "$rule_content" | sudo tee "$rule_file" > /dev/null
    
    sudo udevadm control --reload-rules
    echo ""
    echo -e "${GREEN}$TXT_RULE_SAVED${NC}"
    if [ "$mode" == "trap" ]; then
         echo -e "${RED}$TXT_TRAP_DONE_WARN${NC}"
    else
         echo -e "${GREEN}$TXT_KILL_DONE_INFO${NC}"
    fi
}

function list_devices() {
    echo ""
    echo -e "${GREEN}═══════════════════════════════════${NC}"
    echo -e "${YELLOW}$TXT_ACTIVE_RULES${NC}"
    found=0
    
    # Projdeme soubory pravidel
    for f in "$RULE_DIR"/85-killswitch-*.rules; do
        if [ -e "$f" ]; then
            name=$(basename "$f")
            
            # Hezké formátování výpisu (PAST vs KILL)
            if [[ "$name" == *"trap"* ]]; then
                echo -e "${RED}[PAST] $name${NC}"
            else
                echo -e "${GREEN}[KILL] $name${NC}"
            fi
            
            # Nastavíme příznak, že jsme něco našli
            found=1
        fi
    done

    if [ "$found" -eq 0 ]; then
        echo -e "${RED}$TXT_NO_RULES${NC}"
    fi
}

function remove_device() {
    echo ""
    echo -e "${YELLOW}$TXT_DELETE_RULE${NC}"
    mapfile -t rules < <(ls "$RULE_DIR" | grep "85-killswitch-")
    if [ ${#rules[@]} -eq 0 ]; then
        echo -e "${RED}$TXT_NO_RULES${NC}"
        return
    fi

    for i in "${!rules[@]}"; do
        echo "[$((i+1))] ${rules[$i]}"
    done

    echo ""
    read -p "$TXT_ENTER_DEV_NUM" idx
    sel=$((idx - 1))

    if ! [[ "$idx" =~ ^[0-9]+$ ]] || [ "$sel" -lt 0 ] || [ "$sel" -ge "${#rules[@]}" ]; then
        echo "$TXT_INVALID_CHOICE"
        return
    fi

    sudo rm "$RULE_DIR/${rules[$sel]}"
    sudo udevadm control --reload-rules
    echo "$TXT_DELETED"
}

function bulk_remove_all() {
    sudo rm -f "$RULE_DIR"/85-killswitch-*.rules
    sudo udevadm control --reload-rules
    echo "$TXT_ALL_DELETED"
}

function create_keyboard_shortcut() {
    echo ""
    echo -e "${YELLOW}$TXT_AUTO_SHORTCUT${NC}"

    # 1. Zjištění reálného uživatele
    REAL_USER=$(logname 2>/dev/null || echo $SUDO_USER)
    
    if [ -z "$REAL_USER" ]; then
        echo -e "${RED}$TXT_ERR_USER${NC}"
        return
    fi
    
    # Získání domovského adresáře
    USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
    SHORTCUT_SCRIPT="$USER_HOME/kill.sh"

    # --- KROK 1: SKRIPT ---
    # Vytvoření skriptu kill.sh
    cat <<EOF > "$SHORTCUT_SCRIPT"
#!/bin/bash
# Vynucené vypnutí bez dotazů
sudo /bin/systemctl poweroff -i
EOF
    chmod +x "$SHORTCUT_SCRIPT"
    chown $REAL_USER:$REAL_USER "$SHORTCUT_SCRIPT"
    echo -e "${GREEN}$TXT_SCRIPT_CREATED${NC} $SHORTCUT_SCRIPT"

    # --- KROK 2: SUDOERS ---
    SUDO_FILE="/etc/sudoers.d/killswitch-$REAL_USER"
    
    echo "$TXT_SETTING_PERMS $SUDO_FILE..."
    
    # Zápis pomocí 'tee'
    echo "$REAL_USER ALL=(ALL) NOPASSWD: /bin/systemctl poweroff -i" | sudo tee "$SUDO_FILE" > /dev/null
    sudo chmod 0440 "$SUDO_FILE"
    
    # Kontrola syntaxe
    if sudo visudo -c -f "$SUDO_FILE" > /dev/null; then
        echo -e "${GREEN}$TXT_PERMS_SET${NC}"
    else
        echo -e "${RED}$TXT_ERR_SUDOERS${NC}"
        sudo rm "$SUDO_FILE"
        return
    fi

    # --- KROK 3: GNOME ZKRATKA ---
    echo "$TXT_SETTING_GNOME"
    
    USER_PID=$(pgrep -u "$REAL_USER" "gnome-session" | head -n 1)
    if [ -z "$USER_PID" ]; then
        USER_PID=$(pgrep -u "$REAL_USER" "dbus-daemon" | head -n 1)
    fi
    
    if [ -n "$USER_PID" ]; then
        export DBUS_SESSION_BUS_ADDRESS=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/$USER_PID/environ | tr '\0' '\n' | grep DBUS_SESSION_BUS_ADDRESS | cut -d= -f2-)
    else
        echo -e "${RED}$TXT_ERR_DBUS${NC}"
        return
    fi

    KEY_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom-killswitch/"
    
    CURRENT_LIST=$(sudo -u "$REAL_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
    
    if [[ "$CURRENT_LIST" == "@as []" || "$CURRENT_LIST" == "[]" ]]; then
        NEW_LIST="['$KEY_PATH']"
    else
        if [[ "$CURRENT_LIST" != *"$KEY_PATH"* ]]; then
            NEW_LIST="${CURRENT_LIST%]}, '$KEY_PATH']"
        else
            NEW_LIST="$CURRENT_LIST"
        fi
    fi

    sudo -u "$REAL_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$NEW_LIST"
    
    sudo -u "$REAL_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KEY_PATH name "Killswitch Panic"
    
    sudo -u "$REAL_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KEY_PATH command "$SHORTCUT_SCRIPT"
    
    sudo -u "$REAL_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KEY_PATH binding "<Control>Return"

    echo -e "${GREEN}$TXT_DONE_SHORTCUT${NC}"
}


function remove_keyboard_shortcut() {
    echo ""
    echo -e "${YELLOW}$TXT_REMOVING_SHORTCUT${NC}"

    REAL_USER=$(logname 2>/dev/null || echo $SUDO_USER)
    if [ -z "$REAL_USER" ]; then
        echo -e "${RED}$TXT_ERR_USER${NC}"
        return
    fi
    USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
    SHORTCUT_SCRIPT="$USER_HOME/kill.sh"
    SUDO_FILE="/etc/sudoers.d/killswitch-$REAL_USER"

    if [ -f "$SHORTCUT_SCRIPT" ]; then
        rm "$SHORTCUT_SCRIPT"
        echo -e "${GREEN}$TXT_DELETED_SCRIPT${NC} $SHORTCUT_SCRIPT"
    else
        echo "$TXT_SCRIPT_NOT_FOUND"
    fi

    if [ -f "$SUDO_FILE" ]; then
        sudo rm "$SUDO_FILE"
        echo -e "${GREEN}$TXT_REMOVED_SUDOERS${NC} $SUDO_FILE"
    else
        echo "$TXT_SUDOERS_NOT_FOUND"
    fi

    echo "$TXT_DELETING_GNOME"

    USER_PID=$(pgrep -u "$REAL_USER" "gnome-session" | head -n 1)
    if [ -z "$USER_PID" ]; then
        USER_PID=$(pgrep -u "$REAL_USER" "dbus-daemon" | head -n 1)
    fi

    if [ -n "$USER_PID" ]; then
        export DBUS_SESSION_BUS_ADDRESS=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/$USER_PID/environ | tr '\0' '\n' | grep DBUS_SESSION_BUS_ADDRESS | cut -d= -f2-)
        
        KEY_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom-killswitch/"
        
        sudo -u "$REAL_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" gsettings reset org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KEY_PATH name
        sudo -u "$REAL_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" gsettings reset org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KEY_PATH command
        sudo -u "$REAL_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" gsettings reset org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KEY_PATH binding
        
        CURRENT_LIST=$(sudo -u "$REAL_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
        
        NEW_LIST=$(echo "$CURRENT_LIST" | sed "s|, '$KEY_PATH'||" | sed "s|'$KEY_PATH', ||" | sed "s|'$KEY_PATH'||")
        
        sudo -u "$REAL_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$NEW_LIST"
        
        echo -e "${GREEN}$TXT_SHORTCUT_REMOVED${NC}"
    else
        echo -e "${RED}$TXT_ERR_DBUS${NC}"
    fi
}

# === Main loop ===
while true; do
    show_menu
    case $choice in
        1) add_device_logic "kill" ;;
        2) add_device_logic "trap" ;;
        3) list_devices ;;
        4) remove_device ;;
        5) bulk_remove_all ;;
        6) create_keyboard_shortcut ;;
        7) remove_keyboard_shortcut ;;
        8) sudo udevadm control --reload-rules; echo -e "${GREEN}$TXT_RELOADED${NC}" ;;
        9) echo "$TXT_EXITING"; exit 0 ;;
        *) echo -e "${RED}$TXT_INVALID_CHOICE${NC}" ;;
    esac
done