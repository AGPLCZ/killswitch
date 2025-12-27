#!/usr/bin/env python3
import os
import sys
import subprocess
import re
import tkinter as tk
from tkinter import messagebox, ttk

# --- KONFIGURACE ---
RULE_DIR = "/etc/udev/rules.d"
SCRIPT_PATH = "/root/killswitch.sh"
LOG_PATH = "/root/usbkill.log"
REFRESH_INTERVAL = 2000  # Interval kontroly v ms (2 sekundy)

def check_root():
    if os.geteuid() != 0:
        messagebox.showerror("Chyba oprávnění", "Aplikaci je nutné spouštět jako ROOT (sudo)!")
        sys.exit(1)

def ensure_shutdown_script():
    content = f"""#!/bin/bash
echo "$(date) - KILLSWITCH SPUŠTĚN" >> "{LOG_PATH}"
/bin/systemctl poweroff -i --no-block
"""
    try:
        with open(SCRIPT_PATH, "w") as f:
            f.write(content)
        os.chmod(SCRIPT_PATH, 0o755)
    except Exception as e:
        messagebox.showerror("Chyba", f"Nelze vytvořit {SCRIPT_PATH}:\n{e}")

def reload_udev():
    subprocess.run(["udevadm", "control", "--reload-rules"])

def get_serial(dev_path):
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

def get_usb_devices():
    """Vrátí seznam POUZE VÝMĚNNÝCH zařízení."""
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
            
            # --- PŘÍSNÁ FILTRACE ---
            # Pokud není removable, vůbec ho nepřidáme do seznamu.
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
                        # Musí být explicitně "1" nebo "removable"
                        if content == "1" or content == "removable" or content == "unknown":
                             # Některé flashky hlásí unknown, ale raději to povolíme než zakážeme, 
                             # ovšem 'fixed' a '0' striktně zahazujeme.
                             pass
                        if content != "fixed" and content != "0":
                            is_removable = True
            except Exception:
                is_removable = False 

            if is_removable:
                # Načíst sériové číslo
                dev_path_full = f"/dev/bus/usb/{bus}/{dev}"
                serial = get_serial(dev_path_full)
                
                # Unikátní klíč pro porovnání změn v GUI
                unique_id = f"{vid}:{pid}-{serial}"
                
                devices.append({
                    "line": f"{name} ({vid}:{pid})",
                    "vid": vid,
                    "pid": pid,
                    "serial": serial,
                    "uid": unique_id
                })
                
    except Exception as e:
        print(f"Chyba scanování: {e}")
        
    return devices

def create_rule(device, mode):
    ensure_shutdown_script()
    vid = device['vid']
    pid = device['pid']
    serial = device['serial']
    
    rule_name = f"85-killswitch-{vid}-{pid}.rules"
    if mode == "trap":
        rule_name = f"85-killswitch-trap-{vid}-{pid}.rules"
        
    path = os.path.join(RULE_DIR, rule_name)
    
    if mode == "trap":
        # PAST (Připojení) - Vyžaduje SERIAL pro bezpečnost
        serial_part = ""
        if serial:
            serial_part = f', ATTRS{{serial}}=="{serial}"'
        
        content = f'ACTION=="add", SUBSYSTEM=="usb", ATTRS{{idVendor}}=="{vid}", ATTRS{{idProduct}}=="{pid}"{serial_part}, RUN+="{SCRIPT_PATH}"\n'
        msg = f"Byla vytvořena PAST na zařízení:\n{device['line']}\n\nVAROVÁNÍ: Počítač se vypne OKAMŽITĚ po vložení tohoto klíče!"
    else:
        # KILL (Odpojení) - Bez serialu pro spolehlivost
        content = f'ACTION=="remove", ENV{{PRODUCT}}=="{vid}/{pid}/*", RUN+="{SCRIPT_PATH}"\n'
        msg = f"Killswitch aktivován pro:\n{device['line']}\n\nPočítač se vypne při vytažení tohoto typu zařízení."

    try:
        with open(path, "w") as f:
            f.write(content)
        reload_udev()
        messagebox.showinfo("Hotovo", msg)
        update_ui(force=True)
    except Exception as e:
        messagebox.showerror("Chyba", f"Nelze zapsat pravidlo:\n{e}")

def delete_rule():
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
        messagebox.showerror("Chyba", str(e))

# Globální proměnná pro uložení předchozího stavu
last_devices_state = []

def update_ui(force=False):
    """Hlavní smyčka pro aktualizaci GUI."""
    global current_devices, last_devices_state
    
    # 1. Získat aktuální zařízení
    current_devices = get_usb_devices()
    
    # 2. Porovnat, zda se něco změnilo (aby neproblikával seznam)
    current_ids = [d['uid'] for d in current_devices]
    last_ids = [d['uid'] for d in last_devices_state]
    
    devices_changed = (current_ids != last_ids)
    
    # Aktualizovat seznam zařízení jen při změně
    if devices_changed or force:
        # Uložit aktuální výběr (pokud nějaký je)
        selected_idx = list_dev.curselection()
        selected_uid = None
        if selected_idx and last_devices_state:
            try:
                selected_uid = last_devices_state[selected_idx[0]]['uid']
            except IndexError:
                pass

        list_dev.delete(0, tk.END)
        if not current_devices:
            list_dev.insert(tk.END, "--- Připojte USB zařízení ---")
            list_dev.config(fg="gray")
        else:
            list_dev.config(fg="black")
            for d in current_devices:
                list_dev.insert(tk.END, d['line'])
                
            # Obnovit výběr, pokud zařízení stále existuje
            if selected_uid:
                for i, d in enumerate(current_devices):
                    if d['uid'] == selected_uid:
                        list_dev.selection_set(i)
                        break
        
        last_devices_state = list(current_devices)

    # 3. Aktualizovat pravidla (vždy, nebo jen při změně souborů)
    # Zde to děláme jednoduše - vyčistit a naplnit
    # Pro optimalizaci bychom mohli kontrolovat os.stat složky, ale udev složka je malá.
    existing_rules = set()
    if os.path.exists(RULE_DIR):
        for f in os.listdir(RULE_DIR):
            if f.startswith("85-killswitch-") and f.endswith(".rules"):
                existing_rules.add(f)
    
    # Získáme aktuálně zobrazená pravidla v TreeView
    displayed_rules = set()
    for child in list_rules.get_children():
        displayed_rules.add(list_rules.item(child)['values'][0])
    
    # Pokud se seznam souborů liší, překreslíme
    if existing_rules != displayed_rules or force:
        list_rules.delete(*list_rules.get_children())
        for f in sorted(existing_rules):
            rtype = "KILL (Odpojení)"
            color = "green"
            if "trap" in f:
                rtype = "PAST (Připojení)"
                color = "red"
            
            # Vložení s tagem pro barvu (volitelné vylepšení)
            list_rules.insert("", "end", values=(f, rtype))

    # Naplánovat další běh za X ms
    root.after(REFRESH_INTERVAL, update_ui)

def on_add_kill():
    sel = list_dev.curselection()
    if not sel or not current_devices:
        return
    idx = sel[0]
    create_rule(current_devices[idx], "kill")

def on_add_trap():
    sel = list_dev.curselection()
    if not sel or not current_devices:
        return
    idx = sel[0]
    
    # Extra varování
    res = messagebox.askyesno("Kritické varování", 
        "Chystáte se vytvořit PAST.\n\n"
        "1. Jakmile toto zařízení připojíte, PC se vypne.\n"
        "2. Ujistěte se, že to není systémový disk!\n\n"
        "Opravdu pokračovat?")
    if res:
        create_rule(current_devices[idx], "trap")

# --- GUI SETUP ---
root = tk.Tk()
root.title("USB Killswitch Manager")
root.geometry("650x500")

check_root()

# Frame: Přidání
frame_top = tk.LabelFrame(root, text="Dostupná VÝMĚNNÁ zařízení (Auto-scan)", padx=10, pady=10)
frame_top.pack(fill="both", expand=True, padx=10, pady=5)

list_dev = tk.Listbox(frame_top, height=8, selectmode=tk.SINGLE, font=("Courier", 10))
list_dev.pack(side="left", fill="both", expand=True, pady=5)

scrollbar = tk.Scrollbar(frame_top)
scrollbar.pack(side="right", fill="y", pady=5)
list_dev.config(yscrollcommand=scrollbar.set)
scrollbar.config(command=list_dev.yview)

btn_frame = tk.Frame(root)
btn_frame.pack(fill="x", padx=10, pady=5)

btn_kill = tk.Button(btn_frame, text="🛡️ Vytvořit KILLSWITCH\n(Vypnout při vytažení)", command=on_add_kill, bg="#d4edda", height=2)
btn_kill.pack(side="left", fill="x", expand=True, padx=5)

btn_trap = tk.Button(btn_frame, text="💣 Vytvořit PAST\n(Vypnout při vložení)", command=on_add_trap, bg="#f8d7da", height=2)
btn_trap.pack(side="left", fill="x", expand=True, padx=5)

# Frame: Aktivní pravidla
frame_bot = tk.LabelFrame(root, text="Aktivní ochrany", padx=10, pady=10)
frame_bot.pack(fill="both", expand=True, padx=10, pady=5)

cols = ('Soubor', 'Typ')
list_rules = ttk.Treeview(frame_bot, columns=cols, show='headings', height=5)
list_rules.heading('Soubor', text='Soubor pravidla')
list_rules.heading('Typ', text='Typ ochrany')
list_rules.column('Soubor', width=350)
list_rules.pack(side="left", fill="both", expand=True)

tk.Button(frame_bot, text="Odstranit vybrané pravidlo", command=delete_rule).pack(side="right", fill="y", padx=5)

current_devices = []

# Spuštění automatické aktualizace (poprvé)
update_ui()

root.mainloop()