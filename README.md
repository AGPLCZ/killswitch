# 🛑 Killswitch Manager

[![OS](https://img.shields.io/badge/OS-Ubuntu%20%7C%20Debian-orange?style=flat-square&logo=linux)](https://ubuntu.com/)
[![Language](https://img.shields.io/badge/Language-English%20%7C%20Czech-blue?style=flat-square)](https://github.com/AGPLCZ/killswitch)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

**Killswitch Manager** is a specialized security tool for Linux (Ubuntu/Debian) designed to trigger an immediate system shutdown based on USB events or a global panic shortcut.

---

## 📋 Overview

Killswitch Manager is a powerful security tool for Ubuntu/Debian systems that provides physical security through automated system responses. Whether you need to protect sensitive data from unauthorized access or create an emergency shutdown mechanism, Killswitch Manager has you covered.

### 🎯 Use Cases

- **Data Protection**: Instantly shutdown your system when a security key is removed
- **Physical Security**: Protect against unauthorized USB device connections
- **Emergency Response**: Quick system shutdown via keyboard shortcut
- **Server Security**: CLI interface for headless server deployments

---

## ✨ Features

### 🔐 USB Killswitch
Automatically triggers an immediate shutdown when a specific USB device is **removed** (e.g., YubiKey, security flash drive). Perfect for ensuring your system locks down when you're not present.

### 🧨 USB Trap
Powers off the system the moment an unauthorized or specific USB device is **inserted**. Provides protection against BadUSB attacks and unauthorized physical access attempts.

### 👁️ Smart Device Filtering
Intelligently filters internal components like webcams, Bluetooth modules, and fingerprint readers to prevent accidental triggers. Only monitors devices you care about.

### 🚨 Global Panic Button
Sets up a persistent system-wide shortcut (**Ctrl + Enter** by default) to instantly shutdown the computer in case of emergency. Works across all applications.

### 🌍 Multilingual Support
Fully localized in **English** and **Czech**, including the installer, CLI, and GUI interfaces.

### 🎛️ Dual Interface
- **🖥️ GUI**: User-friendly graphical interface for desktop users
- **⌨️ CLI**: Powerful console tool for advanced users and headless servers

---

## 🛠️ Installation

Fully automated installation with language selection.

```bash
# Clone the repository
git clone https://github.com/AGPLCZ/killswitch.git
cd killswitch

# Make the installer executable
chmod +x install.sh

# Run the installer
sudo ./install.sh
```

The installer will:
- ✅ Install all necessary dependencies
- ✅ Set up GUI and CLI interfaces
- ✅ Create application menu entries
- ✅ Configure the panic button shortcut
- ✅ Set up proper permissions

---

## 🚀 Usage

### Launching the Application

#### Via System Menu
Search for **"Killswitch Manager"** (GUI) or **"Killswitch Console"** (CLI) in your application launcher.

#### Via Terminal

```bash
# Start the CLI version
sudo killswitch

# Start the GUI version
killswitch-gui-start
```

### 🔑 Panic Button Configuration

The manager automatically creates a specialized script at `~/kill.sh` and registers it as a global GNOME shortcut.

**Default Shortcut**: `Ctrl + Enter`

**Manual Command**: `/home/[your_username]/kill.sh`

#### Customizing the Shortcut

1. Open **Settings** → **Keyboard** → **Custom Shortcuts**
2. Find the Killswitch entry or create a new one
3. Set your preferred key combination
4. Point to: `/home/[your_username]/kill.sh`

---

## 📖 Documentation

### Setting Up USB Killswitch

1. Launch Killswitch Manager (GUI or CLI)
2. Select "USB Killswitch" option
3. Connect your security device (YubiKey, USB drive, etc.)
4. Select the device from the list
5. Confirm activation

The system will now shutdown immediately if the device is removed.

### Setting Up USB Trap

1. Launch Killswitch Manager
2. Select "USB Trap" option
3. Choose to trap a specific device or all unknown devices
4. Confirm activation

The system will now shutdown immediately if a matching device is connected.

### Viewing Active Rules

Both GUI and CLI interfaces display currently active rules and allow you to disable them at any time.

---

## 🏗️ Developer Tools

### Building from Source

If you wish to modify the code and rebuild the package:

```bash
# Make the build script executable
chmod +x create.sh

# Build the package
./create.sh
```

This will create a new `.deb` package in the project directory.

### Project Structure

```
killswitch/
├── install.sh              # Main installer script
├── create.sh               # Package builder
├── killswitch-manager.sh   # CLI interface
├── killswitch-gui.py       # GUI interface
├── icons/                  # Application icons
└── README.md              # This file
```

---

## 🗑️ Uninstallation

To completely remove the program, icons, and all active rules:

```bash
sudo ./install.sh
```

Select **Option 2: Uninstall / Odinstalovat**

Or if installed via .deb package:

```bash
sudo apt remove killswitch
```

---

## ⚠️ Important Disclaimer

**This tool triggers a hard shutdown of your system.** Always ensure you save your work before activating a Killswitch or Trap rule. The shutdown is immediate and does not provide time to save unsaved data.

### Security Considerations

- The panic button script is created in your home directory and may be accessible to other users
- USB monitoring requires root privileges
- Rules persist across reboots until manually disabled
- Ensure you have a way to boot and access your system if rules trigger unexpectedly

---



## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.


---

<div align="center">

**Made with ❤️ by [AGPLCZ](https://github.com/AGPLCZ)**

</div>
