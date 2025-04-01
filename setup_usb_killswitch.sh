#!/bin/bash

echo ""
echo "🧠 Detekce připojených USB zařízení..."

# Získání seznamu všech USB zařízení kromě root hubů
devices=$(lsusb | grep -v "Linux Foundation")
IFS=$'\n' read -rd '' -a device_array <<<"$devices"

if [ ${#device_array[@]} -eq 0 ]; then
    echo "❌ Nebyla nalezena žádná USB zařízení (kromě root hubů)."
    exit 1
fi

echo ""
echo "Vyber zařízení, které bude fungovat jako USB killswitch:"
echo ""

# Výpis s indexem začínajícím od 1
for i in "${!device_array[@]}"; do
    device="${device_array[$i]}"
    dev_id=$(echo "$device" | awk '{print $4}' | tr -d :)
    extra=""

    # Upozornění na pravděpodobně vestavěné zařízení
    if [[ "$dev_id" -le 4 ]]; then
        extra=" ⚠️ pravděpodobně interní zařízení"
    fi

    num=$((i+1))
    echo "[$num] $device$extra"
done

# Dotaz na volbu
echo ""
read -p "Zadej číslo zařízení (1-${#device_array[@]}): " index_input
index=$((index_input-1))

# Kontrola vstupu
if ! [[ "$index_input" =~ ^[0-9]+$ ]] || [ "$index" -lt 0 ] || [ "$index" -ge "${#device_array[@]}" ]; then
    echo "❌ Neplatná volba."
    exit 1
fi

# Získání vybraného zařízení
selected="${device_array[$index]}"
vendor=$(echo "$selected" | awk '{print $6}' | cut -d: -f1)
product=$(echo "$selected" | awk '{print $6}' | cut -d: -f2)

echo ""
echo "✅ Vybral jsi: $selected"
echo "   idVendor=$vendor"
echo "   idProduct=$product"

# Potvrzení
read -p "Chceš pokračovat s vytvořením killswitch pro toto zařízení? [y/N]: " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "❌ Přerušeno uživatelem."
    exit 0
fi

# Vytvoření skriptu /root/killswitch.sh
echo "🛠️ Vytvářím /root/killswitch.sh..."
cat <<EOF | sudo tee /root/killswitch.sh > /dev/null
#!/bin/sh
t=\$(date)
echo "\$t - USB killswitch aktivován" >> /root/usbkill.log
shutdown now
EOF

sudo chmod +x /root/killswitch.sh

# Vytvoření pravidla
echo "📜 Vytvářím pravidlo /etc/udev/rules.d/85-my_killswitch_rule.rules..."
cat <<EOF | sudo tee /etc/udev/rules.d/85-my_killswitch_rule.rules > /dev/null
ACTION=="remove", ATTRS{idVendor}=="$vendor", ATTRS{idProduct}=="$product", RUN+="/root/killswitch.sh"
EOF

# Načtení pravidel
echo "🔄 Načítám pravidla..."
sudo udevadm control --reload-rules

# Výpis sudoers řádku
echo ""
echo "✅ HOTOVO! Tvůj USB killswitch je nastaven."
echo ""
username=$(whoami)
echo "⚠️ Přidej do sudoers souboru následující řádek (pomocí: sudo visudo):"
echo ""
echo "$username ALL = NOPASSWD: /sbin/shutdown"
echo ""
echo "💡 Doporučení: Než přidáš shutdown příkaz, můžeš skript testovat jen se zápisem do logu."
