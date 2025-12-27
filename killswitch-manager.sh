#!/bin/bash

RULE_DIR="/etc/udev/rules.d"
SCRIPT_PATH="/root/killswitch.sh"
LOG_PATH="/root/usbkill.log"
SHORTCUT_SCRIPT="$HOME/kill.sh"

YELLOW='\033[1;33m'
GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m'

# Pole pro ukládání filtrovaných zařízení
filtered_devices=()

function show_menu() {
    echo ""
    echo -e "${GREEN}═══════════════════════════════════${NC}"
    echo -e "${GREEN}            KILL-SWITCH            ${NC}"
    echo ""
    echo "1) Přidat nové USB zařízení jako killswitch (vypnutí při ODPOJENÍ)"
    echo "2) Přidat 'PAST' zařízení (vypnutí při ZAPOJENÍ)"
    echo "3) Zobrazit aktivní killswitch pravidla"
    echo "4) Odstranit jedno zařízení"
    echo "5) Hromadně deaktivovat všechna zařízení"
    echo "6) Vytvořit killswitch na klávesovou zkratku"
    echo "7) Odstranit killswitch na klávesovou zkratku"
    echo "8) Znovu načíst pravidla"
    echo "9) Konec"
    echo ""
    read -p "Vyber akci: " choice
}

function create_shutdown_script() {
    if [ ! -f "$SCRIPT_PATH" ]; then
        echo "Vytvářím /root/killswitch.sh..."
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
    echo -e "${YELLOW}Prohledávám a filtruji zařízení...${NC}"
    
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
        echo -e "${RED}Nenalezena žádná VÝMĚNNÁ (removable) USB zařízení.${NC}"
        return
    fi

    echo ""
    if [ "$mode" == "trap" ]; then
        echo -e "${RED}REŽIM PAST: PC se vypne při PŘIPOJENÍ vybraného zařízení!${NC}"
    else
        echo "REŽIM KILLSWITCH: PC se vypne při ODPOJENÍ vybraného zařízení."
    fi

    for i in "${!filtered_devices[@]}"; do
        echo "[$((i+1))] ${filtered_devices[$i]}"
    done

    echo ""
    read -p "Zadej číslo zařízení: " index_input
    index=$((index_input - 1))

    if ! [[ "$index_input" =~ ^[0-9]+$ ]] || [ "$index" -lt 0 ] || [ "$index" -ge "${#filtered_devices[@]}" ]; then
        echo -e "${RED}Neplatná volba.${NC}"
        return
    fi

    raw_line="${filtered_devices[$index]}"
    selected_line=$(echo "$raw_line" | sed 's/\x1b\[[0-9;]*m//g')
    
    if [[ $selected_line =~ ID\ ([0-9a-fA-F]+):([0-9a-fA-F]+) ]]; then
        vid="${BASH_REMATCH[1]}"
        pid="${BASH_REMATCH[2]}"
    else
        echo -e "${RED}Chyba: Nepodařilo se rozpoznat ID zařízení.${NC}"
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
        # Zde MŮŽEME použít serial number, protože zařízení je přítomno
        serial_part=""
        if [ ! -z "$real_serial" ]; then
            echo -e "${GREEN}Nalezeno SN: $real_serial${NC}"
            serial_part=", ATTRS{serial}==\"$real_serial\""
        fi
        rule_content="ACTION==\"add\", SUBSYSTEM==\"usb\", ATTRS{idVendor}==\"$vid\", ATTRS{idProduct}==\"$pid\"$serial_part, RUN+=\"$SCRIPT_PATH\""
    
    else
        # === KILLSWITCH (REMOVE) ===
        # Zde NEPOUŽIJEME serial number. Je to nespolehlivé při vytržení.
        # Vracíme se k metodě ENV{PRODUCT}, která je 100% funkční.
        
        echo -e "${YELLOW}Vytvářím pravidlo pro odpojení (Ignoruji SN pro maximální spolehlivost)...${NC}"
        
        # Formát vid/pid/*
        rule_content="ACTION==\"remove\", ENV{PRODUCT}==\"$vid/$pid/*\", RUN+=\"$SCRIPT_PATH\""
    fi

    echo ""
    echo -e "${YELLOW}--- NÁHLED PRAVIDLA ---${NC}"
    echo "ID Zařízení: $vid:$pid"
    echo "Soubor: $rule_file"
    echo -e "Obsah:\n${BLUE}$rule_content${NC}"
    echo -e "${YELLOW}-----------------------${NC}"
    
    echo "$rule_content" | sudo tee "$rule_file" > /dev/null
    
    sudo udevadm control --reload-rules
    echo ""
    echo -e "${GREEN}Pravidlo uloženo.${NC}"
    if [ "$mode" == "trap" ]; then
         echo -e "${RED}VAROVÁNÍ: PC se vypne, jakmile toto zařízení připojíš.${NC}"
    else
         echo -e "${GREEN}Hotovo. Zkus zařízení vytáhnout.${NC}"
    fi
}

function list_devices() {
    echo ""
    echo -e "${GREEN}═══════════════════════════════════${NC}"
    echo -e "${YELLOW}Aktivní killswitch pravidla:${NC}"
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

    # TOTO JE ČÁST, KTEROU JSI CHTĚL:
    # Pokud found zůstalo 0, vypíšeme hlášku
    if [ "$found" -eq 0 ]; then
        echo -e "${RED}❌ Nejsou přidána žádná pravidla.${NC}"
    fi
}

function remove_device() {
    echo ""
    echo -e "${YELLOW}Smazat pravidlo:${NC}"
    mapfile -t rules < <(ls "$RULE_DIR" | grep "85-killswitch-")
    if [ ${#rules[@]} -eq 0 ]; then
        echo -e "${RED}Žádná pravidla.${NC}"
        return
    fi

    for i in "${!rules[@]}"; do
        echo "[$((i+1))] ${rules[$i]}"
    done

    echo ""
    read -p "Číslo: " idx
    sel=$((idx - 1))

    if ! [[ "$idx" =~ ^[0-9]+$ ]] || [ "$sel" -lt 0 ] || [ "$sel" -ge "${#rules[@]}" ]; then
        echo "Neplatná volba."
        return
    fi

    sudo rm "$RULE_DIR/${rules[$sel]}"
    sudo udevadm control --reload-rules
    echo "Smazáno."
}

function bulk_remove_all() {
    sudo rm -f "$RULE_DIR"/85-killswitch-*.rules
    sudo udevadm control --reload-rules
    echo "Vše smazáno."
}

function create_keyboard_shortcut() {
    echo ""
    echo -e "${YELLOW}Automatické nastavení klávesové zkratky...${NC}"

    # 1. Zjištění reálného uživatele
    # Zkusíme logname, pokud selže, vezmeme SUDO_USER
    REAL_USER=$(logname 2>/dev/null || echo $SUDO_USER)
    
    if [ -z "$REAL_USER" ]; then
        echo -e "${RED}Chyba: Nelze detekovat reálného uživatele.${NC}"
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
    echo -e "${GREEN}1. Skript vytvořen:${NC} $SHORTCUT_SCRIPT"

    # --- KROK 2: SUDOERS (Opraveno pomocí 'tee') ---
    SUDO_FILE="/etc/sudoers.d/killswitch-$REAL_USER"
    
    echo "Nastavuji práva v $SUDO_FILE..."
    
    # Zápis pomocí 'tee' (řeší problém Permission denied)
    echo "$REAL_USER ALL=(ALL) NOPASSWD: /bin/systemctl poweroff -i" | sudo tee "$SUDO_FILE" > /dev/null
    sudo chmod 0440 "$SUDO_FILE"
    
    # Kontrola syntaxe
    if sudo visudo -c -f "$SUDO_FILE" > /dev/null; then
        echo -e "${GREEN}2. Práva nastavena (nebude vyžadováno heslo).${NC}"
    else
        echo -e "${RED}Chyba při kontrole sudoers. Mažu vadný soubor.${NC}"
        sudo rm "$SUDO_FILE"
        return
    fi

    # --- KROK 3: GNOME ZKRATKA (Oprava DBUS) ---
    echo "3. Nastavuji systémovou zkratku (Ctrl+Enter)..."
    
    # Musíme najít PID procesu uživatele, abychom se napojili na jeho DBUS
    USER_PID=$(pgrep -u "$REAL_USER" "gnome-session" | head -n 1)
    if [ -z "$USER_PID" ]; then
        USER_PID=$(pgrep -u "$REAL_USER" "dbus-daemon" | head -n 1)
    fi
    
    if [ -n "$USER_PID" ]; then
        # Export DBUS adresy z běžícího procesu
        export DBUS_SESSION_BUS_ADDRESS=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/$USER_PID/environ | tr '\0' '\n' | grep DBUS_SESSION_BUS_ADDRESS | cut -d= -f2-)
    else
        echo -e "${RED}Varování: Nelze najít grafickou relaci uživatele (DBUS). Zkratku nelze nastavit automaticky.${NC}"
        return
    fi

    KEY_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom-killswitch/"
    
    # Čtení aktuálního nastavení (pod uživatelem s DBUS adresou)
    CURRENT_LIST=$(sudo -u "$REAL_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
    
    # Pokud seznam neexistuje nebo je prázdný
    if [[ "$CURRENT_LIST" == "@as []" || "$CURRENT_LIST" == "[]" ]]; then
        NEW_LIST="['$KEY_PATH']"
    else
        # Pokud tam naše cesta není, přidáme ji
        if [[ "$CURRENT_LIST" != *"$KEY_PATH"* ]]; then
            NEW_LIST="${CURRENT_LIST%]}, '$KEY_PATH']"
        else
            NEW_LIST="$CURRENT_LIST"
        fi
    fi

    # Zápis nového seznamu
    sudo -u "$REAL_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$NEW_LIST"
    
    # Nastavení konkrétních hodnot zkratky
    sudo -u "$REAL_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KEY_PATH name "Killswitch Panic"
    
    sudo -u "$REAL_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KEY_PATH command "$SHORTCUT_SCRIPT"
    
    sudo -u "$REAL_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KEY_PATH binding "<Control>Return"

    echo -e "${GREEN}✅ Hotovo! Nyní můžeš stisknout Ctrl + Enter pro vypnutí PC.${NC}"
}


function remove_keyboard_shortcut() {
    echo ""
    echo -e "${YELLOW}Odstraňuji klávesovou zkratku a soubory...${NC}"

    # 1. Zjištění reálného uživatele (stejná logika jako při vytváření)
    REAL_USER=$(logname 2>/dev/null || echo $SUDO_USER)
    if [ -z "$REAL_USER" ]; then
        echo -e "${RED}Chyba: Nelze detekovat reálného uživatele.${NC}"
        return
    fi
    USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
    SHORTCUT_SCRIPT="$USER_HOME/kill.sh"
    SUDO_FILE="/etc/sudoers.d/killswitch-$REAL_USER"

    # 2. Mazání souborů
    if [ -f "$SHORTCUT_SCRIPT" ]; then
        rm "$SHORTCUT_SCRIPT"
        echo -e "${GREEN}Smazán skript:${NC} $SHORTCUT_SCRIPT"
    else
        echo "Skript $SHORTCUT_SCRIPT nenalezen (již smazán?)"
    fi

    if [ -f "$SUDO_FILE" ]; then
        sudo rm "$SUDO_FILE"
        echo -e "${GREEN}Odebrána práva sudoers:${NC} $SUDO_FILE"
    else
        echo "Sudoers soubor nenalezen."
    fi

    # 3. Mazání zkratky z GNOME (gsettings)
    echo "Mažu zkratku ze systému..."

    # Získání PID a DBUS (nutné pro přístup k nastavení uživatele)
    USER_PID=$(pgrep -u "$REAL_USER" "gnome-session" | head -n 1)
    if [ -z "$USER_PID" ]; then
        USER_PID=$(pgrep -u "$REAL_USER" "dbus-daemon" | head -n 1)
    fi

    if [ -n "$USER_PID" ]; then
        export DBUS_SESSION_BUS_ADDRESS=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/$USER_PID/environ | tr '\0' '\n' | grep DBUS_SESSION_BUS_ADDRESS | cut -d= -f2-)
        
        KEY_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom-killswitch/"
        
        # 1. Vymazat konkrétní nastavení kláves
        sudo -u "$REAL_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" gsettings reset org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KEY_PATH name
        sudo -u "$REAL_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" gsettings reset org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KEY_PATH command
        sudo -u "$REAL_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" gsettings reset org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KEY_PATH binding
        
        # 2. Odstranit cestu ze seznamu aktivních zkratek
        CURRENT_LIST=$(sudo -u "$REAL_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
        
        # Použijeme sed pro odstranění řetězce ze seznamu. 
        # Řešíme varianty: na začátku, uprostřed (s čárkou), na konci, nebo jediná položka.
        NEW_LIST=$(echo "$CURRENT_LIST" | sed "s|, '$KEY_PATH'||" | sed "s|'$KEY_PATH', ||" | sed "s|'$KEY_PATH'||")
        
        sudo -u "$REAL_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$NEW_LIST"
        
        echo -e "${GREEN}✅ Zkratka byla úspěšně odstraněna ze systému.${NC}"
    else
        echo -e "${RED}Varování: Nelze se spojit s grafickým prostředím. Zkratku nelze automaticky odebrat (zůstane jako nefunkční).${NC}"
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
        7) remove_keyboard_shortcut ;;  # <--- Nová volba
        8) sudo udevadm control --reload-rules; echo -e "${GREEN}Pravidla znovu načtena.${NC}" ;;
        9) echo "Ukončuji..."; exit 0 ;;
        *) echo -e "${RED}Neplatná volba.${NC}" ;;
    esac
done