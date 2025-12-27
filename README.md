
# 🛑 Killswitch Manager

[![OS](https://img.shields.io/badge/OS-Ubuntu%20%7C%20Debian-orange?style=flat-square&logo=linux)](https://ubuntu.com/)
[![Language](https://img.shields.io/badge/Language-English%20%7C%20Czech-blue?style=flat-square)](https://github.com/AGPLCZ/killswitch)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

> **Killswitch Manager** is a specialized security tool for Linux (Ubuntu/Debian) designed to trigger an immediate system shutdown based on USB events or a global panic shortcut.

---

## 🎛️ Interfaces

The application is designed for both desktop users and server administrators:
- 🖥️ **GUI (Graphical User Interface)** – A user-friendly, interactive tool for desktop users.
- ⌨️ **CLI (Command Line Interface)** – A powerful console tool for advanced users and headless servers.

---

## 🧩 Key Features

- 🔐 **USB Killswitch**
  Triggers an immediate shutdown when a specific USB device is **removed** (e.g., a YubiKey or a security flash drive).
  
- 🧨 **USB Trap**
  Powers off the system the moment an unauthorized or specific USB device is **inserted** (protection against unauthorized physical access).

- 👁️ **Smart Device Filtering**
  Automatically filters internal components (webcams, Bluetooth modules, fingerprint readers) to prevent accidental triggers.

- 🚨 **Global Panic Button**
  Sets up a persistent system shortcut (**Ctrl + Enter**) to instantly shutdown the computer in case of emergency.

- 🌍 **Multilingual Support**
  Fully localized in **English** and **Czech**, including the installer, CLI, and GUI.

---

## 🛠️ Installation

### Option 1: .deb Package (Recommended)
The most professional way to install the manager is via the pre-built Debian package.
1. Download the latest `killswitch_1.0_all.deb` from the **Releases** section.
2. Install it using:
   `sudo apt install ./killswitch_1.0_all.deb`

### Option 2: Installer Script
The installation is fully automated and supports language selection upon startup.

```bash
# Clone the repository
git clone [https://github.com/AGPLCZ/killswitch.git](https://github.com/AGPLCZ/killswitch.git)
cd killswitch

# Run the installer
chmod +x install.sh
sudo ./install.sh


🚀 How to Run
Via System Menu
Search for "Killswitch Manager" (GUI) or "Killswitch Console" (CLI) in your application launcher.

Via Terminal
Bash

# Start the CLI version
sudo killswitch

# Start the GUI version
killswitch-gui-start
🔑 Panic Button (Shortcut)
The manager generates a specialized script at ~/kill.sh and registers it as a global GNOME shortcut.

Default Shortcut: Ctrl + Enter

Manual Command: /home/[your_username]/kill.sh

🏗️ Developer Tools
If you wish to modify the code and rebuild the package, use the provided build script:

Bash

chmod +x create.sh
./create.sh
🗑️ Uninstallation
To completely remove the program, icons, and all active rules, run the installer and select the uninstall option:

Bash

sudo ./install.sh
(Select Option 2: Uninstall / Odinstalovat)

⚠️ Disclaimer: This tool triggers a hard shutdown. Ensure you always save your work before activating a Killswitch or Trap rule. EOF


# 🛑 Killswitch Manager

> **Killswitch Manager** je bezpečnostní nástroj pro Linux (Ubuntu), který umožňuje okamžité vypnutí počítače na základě USB událostí.

---

## 🎛️ Rozhraní

Nabízí dvě rozhraní:
- 🖥️ **GUI (grafické rozhraní)** – pro běžné uživatele
- ⌨️ **CLI (terminálové rozhraní)** – pro pokročilé uživatele a servery

---

## 🧩 Funkce

- 🔐 **USB Killswitch**  
  Automatické vypnutí počítače při *odpojení* konkrétního USB zařízení  
  (např. YubiKey, bezpečnostní flash disk)

- 🧨 **USB Past (USB Trap)**  
  Vypnutí počítače při *připojení* neznámého nebo konkrétního USB zařízení  
  (ochrana proti neoprávněnému fyzickému přístupu)

- 👁️ **Chytrá detekce zařízení**  
  Interní zařízení (webkamera, Bluetooth, čtečky otisků prstů apod.) jsou  
  automaticky filtrována, aby nedošlo k falešnému spuštění

- 🚨 **Panic button (klávesová zkratka)**  
  Možnost vytvořit skript pro okamžité vypnutí systému pomocí klávesové zkratky

---

## 🛠️ Instalace

Instalace je plně automatizovaná.

### Stažení repozitáře
```bash
git clone https://github.com/AGPLCZ/killswitch.git
cd killswitch
```

### Spuštění instalátoru
```bash
chmod +x install.sh
sudo ./install.sh
```

### Volba instalace
```
1) Instalovat kompletní balík
```

Instalátor vše nastaví a vytvoří ikony v menu aplikací.

---

## 🔑 KILL KEY

### Změna klávesové zkratky
- Ubuntu → Nastavení → Klávesnice → Vlastní klávesové zkratky
- Příkaz:
```
/home/username/kill.sh
```

---

## 🚀 Spuštění programu

### Grafické rozhraní (GUI)
- V menu aplikací spusť **Killswitch Manager**

### Terminálové rozhraní (CLI)
```bash
sudo killswitch
```

### Spuštění bez instalace (CLI)
```bash
sudo ./killswitch-manager.sh
```

### Spuštění bez instalace (GUI)
```bash
sudo ./killswitch-gui.py
```

---

## 🗑️ Odinstalace

Pro kompletní odstranění programu, ikon a všech aktivních pravidel spusť:
```bash
sudo ./install.sh
```

A zvol:
```
2) Odinstalovat vše
```

---

