#!/bin/bash

# =================================================================
#  KILLSWITCH DEB PACKAGE BUILDER
#  This script compiles the source files into a installable .deb
# =================================================================

# --- CONFIGURATION ---
APP_NAME="killswitch-manager"
VERSION="1.0"
ARCH="all"
BUILD_DIR="killswitch_build"
DEB_NAME="${APP_NAME}_${VERSION}_${ARCH}.deb"

# Source files (Must exist in the current directory)
SRC_CLI="killswitch-manager.sh"
SRC_GUI="killswitch-gui.py"

# --- COLORS ---
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}📦 Preparing environment to build .deb package...${NC}"

# 0. CHECK SOURCE FILES
if [ ! -f "$SRC_CLI" ]; then
    echo -e "${RED} ERROR: Source file '$SRC_CLI' not found!${NC}"
    exit 1
fi

if [ ! -f "$SRC_GUI" ]; then
    echo -e "${RED} ERROR: Source file '$SRC_GUI' not found!${NC}"
    exit 1
fi

# 1. CREATE DIRECTORY STRUCTURE
# Clean up previous build
if [ -d "$BUILD_DIR" ]; then
    rm -rf "$BUILD_DIR"
fi

mkdir -p "$BUILD_DIR/DEBIAN"
mkdir -p "$BUILD_DIR/usr/local/bin"
mkdir -p "$BUILD_DIR/usr/share/applications"
mkdir -p "$BUILD_DIR/opt/killswitch-gui"

# ---------------------------------------------------------
# 2. COPY SOURCE CODES
# ---------------------------------------------------------

echo "📂 Copying source files..."

# -> CLI Script
cp "$SRC_CLI" "$BUILD_DIR/usr/local/bin/killswitch"
chmod +x "$BUILD_DIR/usr/local/bin/killswitch"

# -> GUI Script (renamed to manager.py inside the package)
cp "$SRC_GUI" "$BUILD_DIR/opt/killswitch-gui/manager.py"
chmod +x "$BUILD_DIR/opt/killswitch-gui/manager.py"

# ---------------------------------------------------------
# 3. GENERATE PACKAGE METADATA
# ---------------------------------------------------------

# -> Control file (Package metadata)
# Description is in English as per Debian standards.
cat << EOF > "$BUILD_DIR/DEBIAN/control"
Package: $APP_NAME
Version: $VERSION
Section: utils
Priority: optional
Architecture: $ARCH
Depends: python3, python3-tk, x11-xserver-utils, udev, sudo
Maintainer: Killswitch Team
Description: USB Killswitch Manager
 A security tool for Linux systems. Triggers an immediate system shutdown
 upon removal or insertion of specific USB devices.
 .
 Features:
  - CLI and GUI interfaces
  - Trap mode (shutdown on insert)
  - Kill mode (shutdown on remove)
  - Panic button shortcut support
EOF

# -> Post-install script
# Runs on the user's machine after installation
cat << 'EOF' > "$BUILD_DIR/DEBIAN/postinst"
#!/bin/bash
set -e

# Ensure executables have correct permissions
chmod +x /usr/local/bin/killswitch
chmod +x /opt/killswitch-gui/manager.py

# Create a safe launcher wrapper for the GUI (handles xhost and pkexec)
cat <<END_LAUNCHER > /usr/local/bin/killswitch-gui-launcher
#!/bin/bash
# Allow root to access the X server (display)
xhost +si:localuser:root > /dev/null 2>&1
# Run the python app with graphical environment variables
pkexec env DISPLAY=\$DISPLAY XAUTHORITY=\$XAUTHORITY /usr/bin/python3 /opt/killswitch-gui/manager.py
END_LAUNCHER

chmod +x /usr/local/bin/killswitch-gui-launcher

# Reload udev rules to ensure system is ready
udevadm control --reload-rules || true

echo "Killswitch Manager installation completed."
EOF
chmod 755 "$BUILD_DIR/DEBIAN/postinst"

# ---------------------------------------------------------
# 4. GENERATE DESKTOP ICONS (Multilingual)
# ---------------------------------------------------------

# -> CLI Icon
cat << EOF > "$BUILD_DIR/usr/share/applications/killswitch-cli.desktop"
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

# -> GUI Icon
cat << EOF > "$BUILD_DIR/usr/share/applications/killswitch-gui.desktop"
[Desktop Entry]
Name=Killswitch Manager
Name[cs]=Killswitch Manager
Comment=USB Protection Management (GUI)
Comment[cs]=Správa USB ochrany (GUI)
Exec=/usr/local/bin/killswitch-gui-launcher
Icon=security-high
Terminal=false
Type=Application
Categories=Utility;System;Settings;
EOF

# ---------------------------------------------------------
# 5. BUILD THE PACKAGE
# ---------------------------------------------------------
echo "Building .deb package..."
dpkg-deb --build "$BUILD_DIR" "$DEB_NAME"

# Cleanup
echo "Cleaning up build directory..."
rm -rf "$BUILD_DIR"

echo ""
echo -e "${GREEN}SUCCESS! Package created: $DEB_NAME${NC}"
echo "   Contains updated versions of:"
echo "   - $SRC_CLI"
echo "   - $SRC_GUI"
echo ""
echo "To install, run: sudo apt install ./$DEB_NAME"