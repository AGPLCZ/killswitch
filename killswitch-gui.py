#!/usr/bin/env python3
import os
import sys
import subprocess
import re
import tkinter as tk
from tkinter import messagebox, ttk

# ==========================================
#  LOCALIZATION / JAZYKY
# ==========================================
CURRENT_LANG = "en"  # Default language

LANG = {
    "cs": {
        "app_title": "USB Killswitch Manager",
        "err_perm_title": "Chyba oprávnění",
        "err_perm_msg": "Aplikaci je nutné spouštět jako ROOT (sudo)!",
        "err_file_create": "Nelze vytvořit soubor:\n{}",
        "err_scan": "Chyba scanování USB: {}",
        "err_write_rule": "Nelze zapsat pravidlo:\n{}",
        "err_delete": "Chyba při mazání: {}",
        "msg_done": "Hotovo",
        "msg_trap_created": "Byla vytvořena PAST na zařízení:\n{}\n\nVAROVÁNÍ: Počítač se vypne OKAMŽITĚ po vložení tohoto klíče!",
        "msg_kill_created": "Killswitch aktivován pro:\n{}\n\nPočítač se vypne při vytažení tohoto typu zařízení.",
        "msg_connect_usb": "--- Připojte USB zařízení ---",
        "warn_trap_title": "Kritické varování",
        "warn_trap_msg": "Chystáte se vytvořit PAST.\n\n1. Jakmile toto zařízení připojíte, PC se vypne.\n2. Ujistěte se, že to není systémový disk!\n\nOpravdu pokračovat?",
        "frame_dev_title": "Dostupná VÝMĚNNÁ zařízení (Auto-scan)",
        "btn_kill": "🛡️ Vytvořit KILLSWITCH\n(Vypnout při vytažení)",
        "btn_trap": "💣 Vytvořit PAST\n(Vypnout při vložení)",
        "frame_rules_title": "Aktivní ochrany",
        "col_file": "Soubor pravidla",
        "col_type": "Typ ochrany",
        "btn_delete": "Odstranit vybrané pravidlo",
        "type_trap": "PAST (Připojení)",
        "type_kill": "KILL (Odpojení)",
        "lang_switch": "Switch to English 🇬🇧"
    },
    "en": {
        "app_title": "USB Killswitch Manager",
        "err_perm_title": "Permission Error",
        "err_perm_msg": "Application must run as ROOT (sudo)!",
        "err_file_create": "Cannot create file:\n{}",
        "err_scan": "USB Scan Error: {}",
        "err_write_rule": "Cannot write rule:\n{}",
        "err_delete": "Error deleting rule: {}",
        "msg_done": "Done",
        "msg_trap_created": "TRAP created for device:\n{}\n\nWARNING: Computer will shutdown IMMEDIATELY when this key is inserted!",
        "msg_kill_created": "Killswitch activated for:\n{}\n\nComputer will shutdown when this device is removed.",
        "msg_connect_usb": "--- Connect USB Device ---",
        "warn_trap_title": "Critical Warning",
        "warn_trap_msg": "You are about to create a TRAP.\n\n1. As soon as you insert this device, PC will shutdown.\n2. Make sure this is not your system drive!\n\nContinue?",
        "frame_dev_title": "Available REMOVABLE Devices (Auto-scan)",
        "btn_kill": "🛡️ Create KILLSWITCH\n(Shutdown on remove)",
        "btn_trap": "💣 Create TRAP\n(Shutdown on insert)",
        "frame_rules_title": "Active Protections",
        "col_file": "Rule File",
        "col_type": "Protection Type",
        "btn_delete": "Delete Selected Rule",
        "type_trap": "TRAP (Insertion)",
        "type_kill": "KILL (Removal)",
        "lang_switch": "Přepnout na Češtinu 🇨🇿"
    },
    "es": {
        "app_title": "Administrador USB Killswitch",
        "err_perm_title": "Error de permisos",
        "err_perm_msg": "¡La aplicación debe ejecutarse como ROOT (sudo)!",
        "err_file_create": "No se puede crear el archivo:\n{}",
        "err_scan": "Error al escanear USB: {}",
        "err_write_rule": "No se puede escribir la regla:\n{}",
        "err_delete": "Error al eliminar regla: {}",
        "msg_done": "Hecho",
        "msg_trap_created": "TRAMPA creada para el dispositivo:\n{}\n\nADVERTENCIA: ¡El ordenador se apagará INMEDIATAMENTE al insertar esta llave!",
        "msg_kill_created": "Killswitch activado para:\n{}\n\nEl ordenador se apagará al retirar este tipo de dispositivo.",
        "msg_connect_usb": "--- Conecta un dispositivo USB ---",
        "warn_trap_title": "Advertencia crítica",
        "warn_trap_msg": "Estás a punto de crear una TRAMPA.\n\n1. Tan pronto como insertes este dispositivo, el PC se apagará.\n2. ¡Asegúrate de que no sea el disco del sistema!\n\n¿Continuar?",
        "frame_dev_title": "Dispositivos EXTRAÍBLES disponibles (Auto-escaneo)",
        "btn_kill": "🛡️ Crear KILLSWITCH\n(Apagar al retirar)",
        "btn_trap": "💣 Crear TRAMPA\n(Apagar al insertar)",
        "frame_rules_title": "Protecciones activas",
        "col_file": "Archivo de regla",
        "col_type": "Tipo de protección",
        "btn_delete": "Eliminar regla seleccionada",
        "type_trap": "TRAMPA (Inserción)",
        "type_kill": "KILL (Retirada)",
        "lang_switch": "Cambiar a Inglés 🇬🇧"
    },
    "de": {
        "app_title": "USB Killswitch Manager",
        "err_perm_title": "Berechtigungsfehler",
        "err_perm_msg": "Die Anwendung muss als ROOT (sudo) ausgeführt werden!",
        "err_file_create": "Datei kann nicht erstellt werden:\n{}",
        "err_scan": "USB-Scan-Fehler: {}",
        "err_write_rule": "Regel kann nicht geschrieben werden:\n{}",
        "err_delete": "Fehler beim Löschen der Regel: {}",
        "msg_done": "Fertig",
        "msg_trap_created": "FALLE erstellt für Gerät:\n{}\n\nWARNUNG: Der Computer wird SOFORT heruntergefahren, wenn dieser Schlüssel eingesteckt wird!",
        "msg_kill_created": "Killswitch aktiviert für:\n{}\n\nComputer wird heruntergefahren, wenn dieses Gerät entfernt wird.",
        "msg_connect_usb": "--- USB-Gerät anschließen ---",
        "warn_trap_title": "Kritische Warnung",
        "warn_trap_msg": "Sie sind dabei, eine FALLE zu erstellen.\n\n1. Sobald Sie dieses Gerät einstecken, wird der PC heruntergefahren.\n2. Stellen Sie sicher, dass dies nicht das Systemlaufwerk ist!\n\nFortfahren?",
        "frame_dev_title": "Verfügbare WECHSELBARTE Geräte (Auto-Scan)",
        "btn_kill": "🛡️ KILLSWITCH erstellen\n(Herunterfahren beim Entfernen)",
        "btn_trap": "💣 FALLE erstellen\n(Herunterfahren beim Einstecken)",
        "frame_rules_title": "Aktive Schutzmaßnahmen",
        "col_file": "Regeldatei",
        "col_type": "Schutztyp",
        "btn_delete": "Ausgewählte Regel löschen",
        "type_trap": "FALLE (Einstecken)",
        "type_kill": "KILL (Entfernen)",
        "lang_switch": "Wechseln zu Englisch 🇬🇧"
    },
    "fr": {
        "app_title": "Gestionnaire USB Killswitch",
        "err_perm_title": "Erreur de permission",
        "err_perm_msg": "L'application doit être exécutée en ROOT (sudo) !",
        "err_file_create": "Impossible de créer le fichier :\n{}",
        "err_scan": "Erreur de scan USB : {}",
        "err_write_rule": "Impossible d'écrire la règle :\n{}",
        "err_delete": "Erreur lors de la suppression de la règle : {}",
        "msg_done": "Terminé",
        "msg_trap_created": "PIÈGE créé pour le périphérique :\n{}\n\nATTENTION : L'ordinateur s'éteindra IMMÉDIATEMENT à l'insertion de cette clé !",
        "msg_kill_created": "Killswitch activé pour :\n{}\n\nL'ordinateur s'éteindra lors du retrait de ce type de périphérique.",
        "msg_connect_usb": "--- Connectez un périphérique USB ---",
        "warn_trap_title": "Avertissement critique",
        "warn_trap_msg": "Vous êtes sur le point de créer un PIÈGE.\n\n1. Dès que vous insérez ce périphérique, le PC s'éteindra.\n2. Assurez-vous que ce n'est pas le disque système !\n\nContinuer ?",
        "frame_dev_title": "Périphériques AMOVIBLES disponibles (Scan automatique)",
        "btn_kill": "🛡️ Créer KILLSWITCH\n(Éteindre au retrait)",
        "btn_trap": "💣 Créer PIÈGE\n(Éteindre à l'insertion)",
        "frame_rules_title": "Protections actives",
        "col_file": "Fichier de règle",
        "col_type": "Type de protection",
        "btn_delete": "Supprimer la règle sélectionnée",
        "type_trap": "PIÈGE (Insertion)",
        "type_kill": "KILL (Retrait)",
        "lang_switch": "Passer à l'anglais 🇬🇧"
    },
    "zh": {
        "app_title": "USB Killswitch 管理器",
        "err_perm_title": "权限错误",
        "err_perm_msg": "应用程序必须以 ROOT（sudo）运行！",
        "err_file_create": "无法创建文件：\n{}",
        "err_scan": "USB 扫描错误：{}",
        "err_write_rule": "无法写入规则：\n{}",
        "err_delete": "删除规则出错：{}",
        "msg_done": "完成",
        "msg_trap_created": "为设备创建了陷阱：\n{}\n\n警告：插入此钥匙后，计算机会立即关机！",
        "msg_kill_created": "Killswitch 已激活：\n{}\n\n拔出该设备时计算机会关机。",
        "msg_connect_usb": "--- 连接 USB 设备 ---",
        "warn_trap_title": "严重警告",
        "warn_trap_msg": "您即将创建一个陷阱。\n\n1. 插入此设备后，PC 将立即关机。\n2. 确保这不是系统盘！\n\n继续？",
        "frame_dev_title": "可用可移动设备（自动扫描）",
        "btn_kill": "🛡️ 创建 KILLSWITCH\n(拔出时关机)",
        "btn_trap": "💣 创建陷阱\n(插入时关机)",
        "frame_rules_title": "有效保护",
        "col_file": "规则文件",
        "col_type": "保护类型",
        "btn_delete": "删除选定规则",
        "type_trap": "陷阱 (插入)",
        "type_kill": "KILL (拔出)",
        "lang_switch": "切换到英语 🇬🇧"
    },
    "hi": {
        "app_title": "USB Killswitch प्रबंधक",
        "err_perm_title": "अनुमति त्रुटि",
        "err_perm_msg": "एप्लिकेशन को ROOT (sudo) के रूप में चलाना होगा!",
        "err_file_create": "फ़ाइल नहीं बनाई जा सकती:\n{}",
        "err_scan": "USB स्कैन त्रुटि: {}",
        "err_write_rule": "नियम नहीं लिखा जा सकता:\n{}",
        "err_delete": "नियम हटाने में त्रुटि: {}",
        "msg_done": "पूरा हुआ",
        "msg_trap_created": "उपकरण के लिए ट्रैप बनाया गया:\n{}\n\nचेतावनी: इस कुंजी को डालते ही कंप्यूटर तुरंत बंद हो जाएगा!",
        "msg_kill_created": "Killswitch सक्रिय किया गया:\n{}\n\nइस प्रकार के उपकरण को हटाने पर कंप्यूटर बंद हो जाएगा।",
        "msg_connect_usb": "--- USB उपकरण कनेक्ट करें ---",
        "warn_trap_title": "सावधानीपूर्वक चेतावनी",
        "warn_trap_msg": "आप एक ट्रैप बनाने वाले हैं।\n\n1. इस उपकरण को डालते ही PC बंद हो जाएगा।\n2. सुनिश्चित करें कि यह सिस्टम ड्राइव नहीं है!\n\nजारी रखें?",
        "frame_dev_title": "उपलब्ध रिमूवेबल उपकरण (ऑटो-स्कैन)",
        "btn_kill": "🛡️ KILLSWITCH बनाएँ\n(हटाने पर बंद करें)",
        "btn_trap": "💣 ट्रैप बनाएँ\n(डालने पर बंद करें)",
        "frame_rules_title": "सक्रिय सुरक्षा",
        "col_file": "नियम फ़ाइल",
        "col_type": "सुरक्षा प्रकार",
        "btn_delete": "चयनित नियम हटाएँ",
        "type_trap": "ट्रैप (इन्सर्शन)",
        "type_kill": "KILL (हटाना)",
        "lang_switch": "अंग्रेज़ी में बदलें 🇬🇧"
    }
    


}

# Mapování pro Combobox: "Hezký název" -> "kód"
LANG_NAMES = {
    "English": "en",
    "Čeština": "cs",
    "Español": "es",
    "Deutsch": "de",
    "Français": "fr",
    "中文": "zh",
    "हिन्दी": "hi"
}
# Inverzní mapa pro nastavení výchozí hodnoty
LANG_CODES = {v: k for k, v in LANG_NAMES.items()}

def t(key):
    """Returns the translated string for the given key."""
    return LANG[CURRENT_LANG].get(key, key)

# ==========================================
#  CONFIGURATION
# ==========================================
RULE_DIR = "/etc/udev/rules.d"
SCRIPT_PATH = "/root/killswitch.sh"
LOG_PATH = "/root/usbkill.log"
REFRESH_INTERVAL = 2000  # Check interval in ms

def check_root():
    """Checks if the script is running with root privileges."""
    if os.geteuid() != 0:
        messagebox.showerror(t("err_perm_title"), t("err_perm_msg"))
        sys.exit(1)

def ensure_shutdown_script():
    """Creates the bash shutdown script if it doesn't exist."""
    content = f"""#!/bin/bash
echo "$(date) - KILLSWITCH TRIGGERED" >> "{LOG_PATH}"
/bin/systemctl poweroff -i --no-block
"""
    try:
        with open(SCRIPT_PATH, "w") as f:
            f.write(content)
        os.chmod(SCRIPT_PATH, 0o755)
    except Exception as e:
        messagebox.showerror(t("err_perm_title"), t("err_file_create").format(e))

def reload_udev():
    """Reloads udev rules so changes take effect immediately."""
    subprocess.run(["udevadm", "control", "--reload-rules"])

def get_serial(dev_path):
    """Retrieves the serial number of a device via udevadm."""
    try:
        result = subprocess.check_output(
            ["udevadm", "info", "--query=property", "--name=" + dev_path],
            stderr=subprocess.DEVNULL
        ).decode("utf-8")
        for line in result.splitlines():
            if line.startswith("ID_SERIAL_SHORT="):
                return line.split("=")[1]
    except:
        return None
    return None

def change_language(event):
    """Handles language change from Combobox."""
    global CURRENT_LANG
    selected_name = combo_lang.get()
    
    # Získáme kód jazyka (cs/en) podle vybraného názvu
    new_lang = LANG_NAMES.get(selected_name)
    
    if new_lang and new_lang != CURRENT_LANG:
        CURRENT_LANG = new_lang
        refresh_ui_texts()
        update_ui(force=True)

def get_usb_devices():
    """Returns a list of REMOVABLE USB devices only."""
    devices = []
    try:
        lsusb_out = subprocess.check_output(["lsusb"]).decode("utf-8")
        lines = lsusb_out.strip().split("\n")
        
        for line in lines:
            if "Linux Foundation" in line or not line.strip():
                continue
            
            parts = line.split()
            try:
                id_index = parts.index("ID")
            except ValueError:
                continue
            
            if len(parts) < id_index + 2:
                continue
                
            bus = parts[1]
            dev = parts[3].rstrip(":")
            vid_pid = parts[id_index + 1]
            
            if ":" not in vid_pid:
                continue
                
            vid, pid = vid_pid.split(":")
            name = " ".join(parts[id_index + 2:])
            
            # --- STRICT FILTERING ---
            is_removable = False
            dev_path = f"/dev/bus/usb/{bus}/{dev}"
            try:
                sys_path = subprocess.check_output(
                    ["udevadm", "info", "-q", "path", "-n", dev_path], 
                    stderr=subprocess.DEVNULL
                ).decode("utf-8").strip()
                
                removable_file = f"/sys{sys_path}/removable"
                
                if os.path.exists(removable_file):
                    with open(removable_file, "r") as f:
                        content = f.read().strip()
                        # Allow '1', 'removable' or 'unknown', strictly deny 'fixed'/'0'
                        if content == "1" or content == "removable" or content == "unknown":
                             pass
                        if content != "fixed" and content != "0":
                            is_removable = True
            except Exception:
                is_removable = False 

            if is_removable:
                dev_path_full = f"/dev/bus/usb/{bus}/{dev}"
                serial = get_serial(dev_path_full)
                
                unique_id = f"{vid}:{pid}-{serial}"
                
                devices.append({
                    "line": f"{name} ({vid}:{pid})",
                    "vid": vid,
                    "pid": pid,
                    "serial": serial,
                    "uid": unique_id
                })
                
    except Exception as e:
        print(t("err_scan").format(e))
        
    return devices

def create_rule(device, mode):
    """Creates a new udev rule for either Kill (remove) or Trap (add)."""
    ensure_shutdown_script()
    vid = device['vid']
    pid = device['pid']
    serial = device['serial']
    
    rule_name = f"85-killswitch-{vid}-{pid}.rules"
    if mode == "trap":
        rule_name = f"85-killswitch-trap-{vid}-{pid}.rules"
        
    path = os.path.join(RULE_DIR, rule_name)
    
    if mode == "trap":
        # TRAP (Insertion) - Requires SERIAL for safety
        serial_part = ""
        if serial:
            serial_part = f', ATTRS{{serial}}=="{serial}"'
        
        content = f'ACTION=="add", SUBSYSTEM=="usb", ATTRS{{idVendor}}=="{vid}", ATTRS{{idProduct}}=="{pid}"{serial_part}, RUN+="{SCRIPT_PATH}"\n'
        msg = t("msg_trap_created").format(device['line'])
    else:
        # KILL (Removal) - Ignore serial for reliability on removal
        content = f'ACTION=="remove", ENV{{PRODUCT}}=="{vid}/{pid}/*", RUN+="{SCRIPT_PATH}"\n'
        msg = t("msg_kill_created").format(device['line'])

    try:
        with open(path, "w") as f:
            f.write(content)
        reload_udev()
        messagebox.showinfo(t("msg_done"), msg)
        update_ui(force=True)
    except Exception as e:
        messagebox.showerror(t("err_perm_title"), t("err_write_rule").format(e))

def delete_rule():
    """Deletes the selected udev rule."""
    sel = list_rules.selection()
    if not sel:
        return
    item = list_rules.item(sel[0])
    filename = item['values'][0]
    try:
        os.remove(os.path.join(RULE_DIR, filename))
        reload_udev()
        update_ui(force=True)
    except Exception as e:
        messagebox.showerror(t("err_perm_title"), t("err_delete").format(e))

# Global variables for state
last_devices_state = []
current_devices = []

def update_ui(force=False):
    """Main UI refresh loop."""
    global current_devices, last_devices_state
    
    # 1. Get current devices
    current_devices = get_usb_devices()
    
    # 2. Check for changes
    current_ids = [d['uid'] for d in current_devices]
    last_ids = [d['uid'] for d in last_devices_state]
    
    devices_changed = (current_ids != last_ids)
    
    # Update device list only if changed or forced
    if devices_changed or force:
        selected_idx = list_dev.curselection()
        selected_uid = None
        if selected_idx and last_devices_state:
            try:
                selected_uid = last_devices_state[selected_idx[0]]['uid']
            except IndexError:
                pass

        list_dev.delete(0, tk.END)
        if not current_devices:
            list_dev.insert(tk.END, t("msg_connect_usb"))
            list_dev.config(fg="gray")
        else:
            list_dev.config(fg="black")
            for d in current_devices:
                list_dev.insert(tk.END, d['line'])
                
            # Restore selection
            if selected_uid:
                for i, d in enumerate(current_devices):
                    if d['uid'] == selected_uid:
                        list_dev.selection_set(i)
                        break
        
        last_devices_state = list(current_devices)

    # 3. Update rules list
    existing_rules = set()
    if os.path.exists(RULE_DIR):
        for f in os.listdir(RULE_DIR):
            if f.startswith("85-killswitch-") and f.endswith(".rules"):
                existing_rules.add(f)
    
    displayed_rules = set()
    for child in list_rules.get_children():
        displayed_rules.add(list_rules.item(child)['values'][0])
    
    # Refresh treeview if file list differs
    if existing_rules != displayed_rules or force:
        list_rules.delete(*list_rules.get_children())
        for f in sorted(existing_rules):
            rtype = t("type_kill")
            if "trap" in f:
                rtype = t("type_trap")
            
            list_rules.insert("", "end", values=(f, rtype))

    # Schedule next run
    root.after(REFRESH_INTERVAL, update_ui)

def on_add_kill():
    """Handler for adding Killswitch."""
    sel = list_dev.curselection()
    if not sel or not current_devices:
        return
    idx = sel[0]
    create_rule(current_devices[idx], "kill")

def on_add_trap():
    """Handler for adding Trap."""
    sel = list_dev.curselection()
    if not sel or not current_devices:
        return
    idx = sel[0]
    
    res = messagebox.askyesno(t("warn_trap_title"), t("warn_trap_msg"))
    if res:
        create_rule(current_devices[idx], "trap")



def refresh_ui_texts():
    """Updates static text on widgets based on CURRENT_LANG."""
    root.title(t("app_title"))
    frame_top.config(text=t("frame_dev_title"))
    btn_kill.config(text=t("btn_kill"))
    btn_trap.config(text=t("btn_trap"))
    frame_bot.config(text=t("frame_rules_title"))
    list_rules.heading('Soubor', text=t("col_file"))
    list_rules.heading('Typ', text=t("col_type"))
    btn_delete.config(text=t("btn_delete"))


# --- GUI SETUP ---
root = tk.Tk()
# Title is set in refresh_ui_texts
root.geometry("850x550")

check_root()

# Header Frame (Language Switch)
frame_header = tk.Frame(root)
frame_header.pack(fill="x", padx=10, pady=5)

# Header Frame (Language Switch)
frame_header = tk.Frame(root)
frame_header.pack(fill="x", padx=10, pady=5)

# --- ZMĚNA: Místo tlačítka dáváme Combobox ---
combo_lang = ttk.Combobox(
    frame_header, 
    values=list(LANG_NAMES.keys()), 
    state="readonly", 
    width=15
)
combo_lang.pack(side="right")
combo_lang.set(LANG_CODES[CURRENT_LANG]) # Nastavit aktuální jazyk
combo_lang.bind("<<ComboboxSelected>>", change_language)
# ---------------------------------------------

# Frame: Devices
frame_top = tk.LabelFrame(root, padx=10, pady=10) # Text set via function
frame_top.pack(fill="both", expand=True, padx=10, pady=5)

list_dev = tk.Listbox(frame_top, height=8, selectmode=tk.SINGLE, font=("Courier", 10))
list_dev.pack(side="left", fill="both", expand=True, pady=5)

scrollbar = tk.Scrollbar(frame_top)
scrollbar.pack(side="right", fill="y", pady=5)
list_dev.config(yscrollcommand=scrollbar.set)
scrollbar.config(command=list_dev.yview)

# Buttons Frame
btn_frame = tk.Frame(root)
btn_frame.pack(fill="x", padx=10, pady=5)

btn_kill = tk.Button(btn_frame, command=on_add_kill, bg="#d4edda", height=2)
btn_kill.pack(side="left", fill="x", expand=True, padx=5)

btn_trap = tk.Button(btn_frame, command=on_add_trap, bg="#f8d7da", height=2)
btn_trap.pack(side="left", fill="x", expand=True, padx=5)

# Frame: Active Rules
frame_bot = tk.LabelFrame(root, padx=10, pady=10)
frame_bot.pack(fill="both", expand=True, padx=10, pady=5)

cols = ('Soubor', 'Typ')
list_rules = ttk.Treeview(frame_bot, columns=cols, show='headings', height=5)
list_rules.column('Soubor', width=300)
list_rules.pack(side="left", fill="both", expand=True)

btn_delete = tk.Button(frame_bot, command=delete_rule)
btn_delete.pack(side="right", fill="y", padx=5)

# Apply initial texts
refresh_ui_texts()

# Start Auto-scan
update_ui()

root.mainloop()