#!/bin/bash

RULE_DIR="/etc/udev/rules.d"
SCRIPT_PATH="/root/killswitch.sh"
LOG_PATH="/root/usbkill.log"

# Barevné výpisy (volitelně vypnout)
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m' # No Color

function show_menu() {
    echo ""
    echo -e "${GREEN}USB Killswitch Manager v0.1${NC}"
    echo "1) Přidat nové zařízení"
    echo "2) Zobrazit aktivní killswitch zařízení"
    echo "3) Odstranit zařízení"
    echo "4) Načíst pravidla znovu"
    echo "5) Konec"
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
    echo "Vyber zařízení, které bude fungovat jako killswitch:"
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

    # Vytvoření skriptu (pokud ještě neexistuje)
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

    # Udev pravidlo
    echo "Vytvářím pravidlo..."
    cat <<EOF | sudo tee "$rule_file" > /dev/null
ACTION=="remove", ATTRS{idVendor}=="$vendor", ATTRS{idProduct}=="$product", RUN+="$SCRIPT_PATH"
EOF

    sudo udevadm control --reload-rules
    echo -e "${GREEN}Pravidlo přidáno a aktivováno.${NC}"
}

function list_devices() {
    echo ""
    echo -e "${YELLOW}Aktivní killswitch pravidla:${NC}"
    found=0
    for f in "$RULE_DIR"/85-killswitch-*.rules; do
        if [ -f "$f" ]; then
            vendor=$(grep -oP 'idVendor\)=="\K[^"]+' "$f")
            product=$(grep -oP 'idProduct\)=="\K[^"]+' "$f")
            echo "- $(basename "$f") ($vendor:$product)"
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
        echo "[$((i+1))] $rule ($vendor:$product)"
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

while true; do
    show_menu
    case $choice in
        1) add_device ;;
        2) list_devices ;;
        3) remove_device ;;
        4) sudo udevadm control --reload-rules; echo -e "${GREEN}Pravidla znovu načtena.${NC}" ;;
        5) echo "Ukončuji..."; exit 0 ;;
        *) echo -e "${RED}Neplatná volba.${NC}" ;;
    esac
done

