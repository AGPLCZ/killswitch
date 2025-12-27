#!/bin/bash

# --- KONFIGURACE ---
BUILD_DIR="killswitch_build"
DEB_NAME="killswitch_1.0_all.deb"

# Zdroje (musí být ve stejné složce)
SRC_CLI="killswitch-manager.sh"
SRC_GUI="killswitch-gui.py"

echo "📦 Příprava prostředí pro sestavení .deb balíčku..."

# 0. KONTROLA ZDROJOVÝCH SOUBORŮ
if [ ! -f "$SRC_CLI" ]; then
    echo "❌ CHYBA: Nenalezen soubor '$SRC_CLI'!"
    exit 1
fi

if [ ! -f "$SRC_GUI" ]; then
    echo "❌ CHYBA: Nenalezen soubor '$SRC_GUI'!"
    exit 1
fi

# 1. VYTVOŘENÍ ADRESÁŘOVÉ STRUKTURY
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/DEBIAN"
mkdir -p "$BUILD_DIR/usr/local/bin"
mkdir -p "$BUILD_DIR/usr/share/applications"
mkdir -p "$BUILD_DIR/opt/killswitch-gui"

# ---------------------------------------------------------
# 2. KOPÍROVÁNÍ ZDROJOVÝCH KÓDŮ (Změna z 'cat' na 'cp')
# ---------------------------------------------------------

echo "📂 Kopíruji zdrojové kódy..."

# -> CLI Script
# Zkopíruje tvůj aktuální killswitch-manager.sh do balíčku jako 'killswitch'
cp "$SRC_CLI" "$BUILD_DIR/usr/local/bin/killswitch"
chmod +x "$BUILD_DIR/usr/local/bin/killswitch"

# -> GUI Script
# Zkopíruje tvůj aktuální killswitch-gui.py do balíčku jako 'manager.py'
cp "$SRC_GUI" "$BUILD_DIR/opt/killswitch-gui/manager.py"
chmod +x "$BUILD_DIR/opt/killswitch-gui/manager.py"

# ---------------------------------------------------------
# 3. POMOCNÉ SOUBORY (Tyto generujeme stále, protože jsou statické)
# ---------------------------------------------------------

# -> Metadata (Control file)
cat << EOF > "$BUILD_DIR/DEBIAN/control"
Package: killswitch-manager
Version: 1.0
Section: utils
Priority: optional
Architecture: all
Depends: python3, python3-tk, x11-xserver-utils, udev, sudo
Maintainer: Killswitch Team
Description: USB Killswitch Manager
 Nástroj pro ochranu počítače. Umožňuje nastavit vypnutí PC
 při vytažení nebo vložení specifického USB zařízení.
 Obsahuje CLI i GUI verzi.
EOF

# -> Po-instalační skript (postinst)
cat << 'EOF' > "$BUILD_DIR/DEBIAN/postinst"
#!/bin/bash
set -e

# Nastavení spustitelnosti
chmod +x /usr/local/bin/killswitch
chmod +x /opt/killswitch-gui/manager.py

# Vytvoření wrapperu pro bezpečné spuštění GUI (řeší xhost a pkexec)
cat <<END_LAUNCHER > /usr/local/bin/killswitch-gui-launcher
#!/bin/bash
xhost +si:localuser:root > /dev/null 2>&1
pkexec env DISPLAY=\$DISPLAY XAUTHORITY=\$XAUTHORITY /usr/bin/python3 /opt/killswitch-gui/manager.py
END_LAUNCHER
chmod +x /usr/local/bin/killswitch-gui-launcher

# Reload udev pravidel
udevadm control --reload-rules || true

echo "Instalace Killswitch Manageru dokončena."
EOF
chmod 755 "$BUILD_DIR/DEBIAN/postinst"

# -> Ikona pro CLI
cat << EOF > "$BUILD_DIR/usr/share/applications/killswitch-cli.desktop"
[Desktop Entry]
Name=Killswitch Console
Comment=Správa USB ochrany (Terminál)
Exec=sudo killswitch
Icon=utilities-terminal
Terminal=true
Type=Application
Categories=Utility;System;
EOF

# -> Ikona pro GUI
cat << EOF > "$BUILD_DIR/usr/share/applications/killswitch-gui.desktop"
[Desktop Entry]
Name=Killswitch Manager
Comment=Správa USB ochrany (GUI)
Exec=/usr/local/bin/killswitch-gui-launcher
Icon=security-high
Terminal=false
Type=Application
Categories=Utility;System;Settings;
EOF

# ---------------------------------------------------------
# 4. SESTAVENÍ .DEB BALÍČKU
# ---------------------------------------------------------
echo "🔨 Sestavuji balíček..."
dpkg-deb --build "$BUILD_DIR" "$DEB_NAME"

echo ""
echo "✅ HOTOVO! Balíček vytvořen: $DEB_NAME"
echo "   Obsahuje aktuální verze souborů:"
echo "   - $SRC_CLI"
echo "   - $SRC_GUI"
echo ""
echo "Složku '$BUILD_DIR' jsem smazal."

rm -rf "$BUILD_DIR"