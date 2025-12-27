#!/bin/bash

RULE_DIR="/etc/udev/rules.d"
SCRIPT_PATH="/root/killswitch.sh"
LOG_PATH="/root/usbkill.log"
SHORTCUT_SCRIPT="$HOME/kill.sh"

YELLOW='\033[1;33m'
GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m'

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
    echo "7) Znovu načíst pravidla"
    echo "8) Konec"
    echo ""
    read -p "Vyber akci: " choice
}

function add_device() {
    echo ""
    echo -e "${YELLOW}Detekce zařízení...${NC}"
    devices=$(lsusb | grep -v "Linux Foundation")
    IFS=$'\n' read -rd '' -a device_array <<<"$devices"

    if [ ${#device_array[@]} -eq 0 ]; then
        echo -e "${RED}Nenalezena žádná USB zařízení.${NC}"
        return
    fi

    echo ""
    echo "Vyber zařízení, které bude fungovat jako killswitch (odpojení = vypnutí):"
    for i in "${!device_array[@]}"; do
        device="${device_array[$i]}"
        dev_id=$(echo "$device" | awk '{print $4}' | tr -d :)
        extra=""
        if [[ "$dev_id" -le 4 ]]; then
            extra=" ⚠️ pravděpodobně interní zařízení"
        fi
        echo "[$((i+1))] $device$extra"
    done

    echo ""
    read -p "Zadej číslo zařízení: " index_input
    index=$((index_input - 1))

    if ! [[ "$index_input" =~ ^[0-9]+$ ]] || [ "$index" -lt 0 ] || [ "$index" -ge "${#device_array[@]}" ]; then
        echo -e "${RED}Neplatná volba.${NC}"
        return
    fi

    selected="${device_array[$index]}"
    vendor=$(echo "$selected" | awk '{print $6}' | cut -d: -f1)
    product=$(echo "$selected" | awk '{print $6}' | cut -d: -f2)
    rule_file="$RULE_DIR/85-killswitch-${vendor}-${product}.rules"

    echo ""
    echo "Vytvářím pravidlo pro zařízení: $selected"
    echo "Vendor: $vendor, Product: $product"
    echo "Soubor: $rule_file"

    # Vytvoření skriptu pro vypnutí, pokud neexistuje
    if [ ! -f "$SCRIPT_PATH" ]; then
        echo "Vytvářím /root/killswitch.sh..."
        cat <<EOF | sudo tee "$SCRIPT_PATH" > /dev/null
#!/bin/sh
t=\$(date)
echo "\$t - USB killswitch aktivován" >> "$LOG_PATH"
shutdown now
EOF
        sudo chmod +x "$SCRIPT_PATH"
    fi

    echo "Vytvářím pravidlo (REMOVE action)..."
    cat <<EOF | sudo tee "$rule_file" > /dev/null
ACTION=="remove", ATTRS{idVendor}=="$vendor", ATTRS{idProduct}=="$product", RUN+="$SCRIPT_PATH"
EOF

    sudo udevadm control --reload-rules
    echo -e "${GREEN}Pravidlo přidáno a aktivováno.${NC}"
}

function add_trap_device() {
    echo ""
    echo -e "${YELLOW}Detekce zařízení pro vytvoření PASTI...${NC}"
    devices=$(lsusb | grep -v "Linux Foundation")
    IFS=$'\n' read -rd '' -a device_array <<<"$devices"

    if [ ${#device_array[@]} -eq 0 ]; then
        echo -e "${RED}Nenalezena žádná USB zařízení.${NC}"
        return
    fi

    echo ""
    echo -e "${RED}POZOR: Vybrané zařízení způsobí vypnutí PC, jakmile bude PŘIPOJENO.${NC}"
    echo "Vyber vzorové zařízení (PC se vypne, když připojíš toto nebo stejný typ):"
    for i in "${!device_array[@]}"; do
        device="${device_array[$i]}"
        echo "[$((i+1))] $device"
    done

    echo ""
    read -p "Zadej číslo zařízení: " index_input
    index=$((index_input - 1))

    if ! [[ "$index_input" =~ ^[0-9]+$ ]] || [ "$index" -lt 0 ] || [ "$index" -ge "${#device_array[@]}" ]; then
        echo -e "${RED}Neplatná volba.${NC}"
        return
    fi

    selected="${device_array[$index]}"
    vendor=$(echo "$selected" | awk '{print $6}' | cut -d: -f1)
    product=$(echo "$selected" | awk '{print $6}' | cut -d: -f2)
    # Přidáno 'trap' do názvu souboru pro přehlednost
    rule_file="$RULE_DIR/85-killswitch-trap-${vendor}-${product}.rules"

    echo ""
    echo "Vytvářím 'trap' pravidlo pro: $selected"
    echo "Vendor: $vendor, Product: $product"

    # Kontrola existence vypínacího skriptu
    if [ ! -f "$SCRIPT_PATH" ]; then
        echo "Vytvářím /root/killswitch.sh..."
        cat <<EOF | sudo tee "$SCRIPT_PATH" > /dev/null
#!/bin/sh
t=\$(date)
echo "\$t - USB killswitch (TRAP) aktivován" >> "$LOG_PATH"
shutdown now
EOF
        sudo chmod +x "$SCRIPT_PATH"
    fi

    echo "Vytvářím pravidlo (ADD action)..."
    # Zde je změna: ACTION je "add" místo "remove"
    cat <<EOF | sudo tee "$rule_file" > /dev/null
ACTION=="add", ATTRS{idVendor}=="$vendor", ATTRS{idProduct}=="$product", RUN+="$SCRIPT_PATH"
EOF

    sudo udevadm control --reload-rules
    echo -e "${GREEN}Pravidlo přidáno.${NC}"
    echo -e "${RED}Varování: Pokud toto zařízení odpojíš a znovu připojíš, PC se vypne!${NC}"
}

function list_devices() {
    echo ""
    echo -e "${GREEN}═══════════════════════════════════${NC}"
    echo -e "${YELLOW}Aktivní killswitch pravidla:${NC}"
    found=0
    # Hledá všechny soubory začínající na 85-killswitch-, včetně trap verzí
    for f in "$RULE_DIR"/85-killswitch-*.rules; do
        if [ -f "$f" ]; then
            vendor=$(grep -oP 'idVendor\)=="\K[^"]+' "$f")
            product=$(grep -oP 'idProduct\)=="\K[^"]+' "$f")
            action=$(grep -oP 'ACTION=="\K[^"]+' "$f")
            
            type_info="[ODPOJENÍ]"
            if [[ "$f" == *"trap"* ]] || [[ "$action" == "add" ]]; then
                type_info="${RED}[PŘIPOJENÍ]${YELLOW}"
            fi
            
            echo "- $type_info $(basename "$f") ($vendor:$product)"
            found=1
        fi
    done

    if [ "$found" -eq 0 ]; then
        echo "Žádná killswitch pravidla nenalezena."
    fi
}

function remove_device() {
    echo ""
    echo -e "${YELLOW}Odstranit killswitch pravidlo:${NC}"
    mapfile -t rules < <(ls "$RULE_DIR" | grep "85-killswitch-")
    if [ ${#rules[@]} -eq 0 ]; then
        echo -e "${RED}Nenalezena žádná pravidla.${NC}"
        return
    fi

    for i in "${!rules[@]}"; do
        rule="${rules[$i]}"
        vendor=$(grep -oP 'idVendor\)=="\K[^"]+' "$RULE_DIR/$rule")
        product=$(grep -oP 'idProduct\)=="\K[^"]+' "$RULE_DIR/$rule")
        
        # Detekce typu pro výpis
        if [[ "$rule" == *"trap"* ]]; then
             info="${RED}(PAST - připojení)${NC}"
        else
             info="(Odpojení)"
        fi
        
        echo "[$((i+1))] $rule ($vendor:$product) $info"
    done

    echo ""
    read -p "Zadej číslo pravidla, které chceš odstranit: " idx
    sel=$((idx - 1))

    if ! [[ "$idx" =~ ^[0-9]+$ ]] || [ "$sel" -lt 0 ] || [ "$sel" -ge "${#rules[@]}" ]; then
        echo -e "${RED}Neplatná volba.${NC}"
        return
    fi

    echo "Mažu ${rules[$sel]}..."
    sudo rm "$RULE_DIR/${rules[$sel]}"
    sudo udevadm control --reload-rules
    echo -e "${GREEN}Pravidlo odstraněno.${NC}"
}

function bulk_remove_all() {
    echo ""
    echo -e "${RED}⚠️  Hromadná deaktivace všech killswitch zařízení${NC}"
    read -p "Opravdu chceš odstranit VŠECHNA pravidla? [y/N]: " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Zrušeno."
        return
    fi

    sudo rm -f "$RULE_DIR"/85-killswitch-*.rules
    sudo udevadm control --reload-rules
    echo -e "${GREEN}Všechna pravidla byla odstraněna.${NC}"

    if [ -f "$SCRIPT_PATH" ]; then
        read -p "Chceš také odstranit /root/killswitch.sh? [y/N]: " confirm_script
        if [[ "$confirm_script" == "y" || "$confirm_script" == "Y" ]]; then
            sudo rm "$SCRIPT_PATH"
            echo -e "${GREEN}/root/killswitch.sh byl smazán.${NC}"
        fi
    fi
}

function create_keyboard_shortcut() {
    echo ""
    echo -e "${YELLOW}Vytvoření killswitch skriptu pro klávesovou zkratku:${NC}"

    cat <<EOF > "$SHORTCUT_SCRIPT"
#!/bin/bash
sudo poweroff -f
EOF

    chmod +x "$SHORTCUT_SCRIPT"

    username=$(whoami)
    echo ""
    echo -e "${GREEN}Soubor uložen jako:${NC} $SHORTCUT_SCRIPT"
    echo ""
    echo -e "${YELLOW}Pro správné fungování přidej do sudoers (pomocí: sudo visudo):${NC}"
    echo "$username ALL = NOPASSWD: /sbin/poweroff"
    echo ""
    echo -e "${YELLOW}Nastavení klávesové zkratky v Ubuntu:${NC}"
    echo "1. Otevři Nastavení → Klávesnice → Vlastní klávesové zkratky"
    echo "2. Klikni na + (Přidat)"
    echo "   Název: KillSwitch"
    echo "   Příkaz: $SHORTCUT_SCRIPT"
    echo "   Zkratka: např. Ctrl + Enter"
    echo ""
}

# === Main loop ===
while true; do
    show_menu
    case $choice in
        1) add_device ;;
        2) add_trap_device ;;
        3) list_devices ;;
        4) remove_device ;;
        5) bulk_remove_all ;;
        6) create_keyboard_shortcut ;;
        7) sudo udevadm control --reload-rules; echo -e "${GREEN}Pravidla znovu načtena.${NC}" ;;
        8) echo "Ukončuji..."; exit 0 ;;
        *) echo -e "${RED}Neplatná volba.${NC}" ;;
    esac
done
