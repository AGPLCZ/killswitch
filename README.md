# Killswitch Manager

**Killswitch Manager** je bezpečnostní nástroj pro Linux (Ubuntu), který umožňuje okamžité vypnutí počítače na základě USB událostí.

Nabízí dvě rozhraní:
- **GUI (grafické rozhraní)** – pro běžné uživatele
- **CLI (terminálové rozhraní)** – pro pokročilé uživatele a servery

---

## Funkce

- **USB Killswitch**  
  Automatické vypnutí počítače při *odpojení* konkrétního USB zařízení  
  (např. YubiKey, bezpečnostní flash disk)

- **USB Past (USB Trap)**  
  Vypnutí počítače při *připojení* neznámého nebo konkrétního USB zařízení  
  (ochrana proti neoprávněnému fyzickému přístupu)

- **Chytrá detekce zařízení**  
  Interní zařízení (webkamera, Bluetooth, čtečky otisků prstů apod.) jsou
  automaticky filtrována, aby nedošlo k falešnému spuštění

- **Panic button (klávesová zkratka)**  
  Možnost vytvořit skript pro okamžité vypnutí systému pomocí klávesové zkratky

---

## Obsah repozitáře

- `install.sh`  
  Hlavní instalační skript, který:
  - zkontroluje a doinstaluje závislosti (Python Tkinter, xhost)
  - nainstaluje CLI i GUI verzi
  - vytvoří systémové ikony v menu aplikací
  - nastaví bezpečné spouštěče

- `killswitch-manager.sh`  
  Jádro aplikace pro terminálové ovládání

- `killswitch-gui.py`  
  Grafické rozhraní napsané v Pythonu (Tkinter)

---

## Instalace

Instalace je plně automatizovaná.

1. Stažení repozitáře:
   ```bash
   git clone https://github.com/AGPLCZ/killswitch.git
   cd killswitch
   ```

2. Spuštění instalátoru:
   ```bash
   chmod +x install.sh
   sudo ./install.sh
   ```

3. V menu instalátoru zvol:
   ```
   1) Instalovat kompletní balík
   ```

Instalátor vše nastaví a vytvoří ikony v menu aplikací.

---

## Použití

### Grafické rozhraní (GUI)

- V menu aplikací spusť **Killswitch Manager**
- Aplikace si vyžádá heslo (vyžaduje root práva pro zápis udev pravidel)
- Připoj USB zařízení, vyber ho ze seznamu
- Zvol:
  - **Vytvořit Killswitch** (reakce na odpojení)
  - **Vytvořit Past** (reakce na připojení)

### Terminálové rozhraní (CLI)

Spuštění příkazem:
```bash
sudo killswitch
```

---

## Nastavení klávesové zkratky (volitelné)

Pro vypnutí počítače klávesovou zkratkou (např. `Ctrl + Alt + K`) je nutné
umožnit vypnutí systému bez zadání hesla.

### 1. Vytvoření spouštěcího skriptu

V GUI nebo CLI zvol možnost **Vytvořit killswitch na klávesovou zkratku**.  
Tím se vytvoří soubor:
```
~/kill.sh
```

### 2. Povolení vypnutí bez hesla

Otevři konfiguraci sudoers:
```bash
sudo visudo
```

Na konec souboru přidej (nahraď `username` svým uživatelským jménem):
```bash
username ALL = NOPASSWD: /bin/systemctl poweroff -i
```

### 3. Nastavení zkratky v Ubuntu

- Nastavení → Klávesnice → Zobrazit a přizpůsobit zkratky
- Vlastní zkratky → Přidat novou
  - Název: `Killswitch`
  - Příkaz: `/home/username/kill.sh`
  - Zkratka: dle libosti (např. `Ctrl + F12`)

---

## Odinstalace

Pro kompletní odstranění programu, ikon a všech aktivních pravidel spusť:
```bash
sudo ./install.sh
```

A zvol:
```
2) Odinstalovat vše
```

---

## Upozornění

Autor nenese odpovědnost za ztrátu neuložených dat způsobenou náhlým vypnutím
počítače při testování nebo používání tohoto nástroje.

Používejte s rozumem.
