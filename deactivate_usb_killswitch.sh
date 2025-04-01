#!/bin/bash

RULE_DIR="/etc/udev/rules.d"
RULE_PREFIX="85-my_killswitch_rule"

echo ""
echo "🧹 Hledám killswitch pravidla..."

# Najdi soubory začínající na správný prefix
mapfile -t rules < <(ls "$RULE_DIR" | grep "$RULE_PREFIX")

if [ ${#rules[@]} -eq 0 ]; then
    echo "❌ Nenalezena žádná killswitch pravidla."
    exit 1
fi

echo ""
echo "Nalezené killswitch pravidlo/pravidla:"
for i in "${!rules[@]}"; do
    rule_file="${rules[$i]}"
    rule_path="$RULE_DIR/$rule_file"
    vendor=$(grep -oP 'idVendor\)=="\K[^"]+' "$rule_path" || echo "?")
    product=$(grep -oP 'idProduct\)=="\K[^"]+' "$rule_path" || echo "?")
    echo "[$((i+1))] $rule_file  ($vendor:$product)"
done

echo ""
read -p "Zadej číslo pravidla, které chceš deaktivovat: " index_input
index=$((index_input - 1))

if ! [[ "$index_input" =~ ^[0-9]+$ ]] || [ "$index" -lt 0 ] || [ "$index" -ge "${#rules[@]}" ]; then
    echo "❌ Neplatná volba."
    exit 1
fi

selected_file="${rules[$index]}"
selected_path="$RULE_DIR/$selected_file"

echo ""
read -p "Opravdu chceš smazat pravidlo $selected_file? [y/N]: " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "❌ Přerušeno uživatelem."
    exit 0
fi

sudo rm "$selected_path"
echo "✅ Pravidlo bylo odstraněno: $selected_file"

# Dotaz na smazání killswitch skriptu
if [ -f /root/killswitch.sh ]; then
    read -p "Chceš také odstranit /root/killswitch.sh? [y/N]: " del_script
    if [[ "$del_script" == "y" || "$del_script" == "Y" ]]; then
        sudo rm /root/killswitch.sh
        echo "🗑️  /root/killswitch.sh byl smazán"
    fi
fi

# Znovunačtení pravidel
echo "🔄 Načítám pravidla znovu..."
sudo udevadm control --reload-rules

echo ""
echo "✅ Killswitch byl úspěšně deaktivován."

