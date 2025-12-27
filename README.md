

# Killswitch Manager

**Killswitch Manager** je bezpečnostní nástroj pro Linux (Ubuntu), který umožňuje okamžité vypnutí počítače na základě USB událostí.

Nabízí dvě rozhraní:
- **GUI (grafické rozhraní)** – pro běžné uživatele
- **CLI (terminálové rozhraní)** – pro pokročilé uživatele a servery

---


## 🧩 Funkce

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

## 🛠️ Instalace

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

## KILL KEY
- nebude třeba zadávat heslo před vypnutím

```bash
sudo visudo
```

#### Vlož
  ```bash
username ALL = NOPASSWD: /sbin/poweroff
username ALL = NOPASSWD: /sbin/shutdown
```

#### klávesová zkratka
- Ubuntu ->  nastavení -> klávesnice -> vlastní klávesové zkratky 
- /home/username/kill.sh


## Spuštění programu

### Grafické rozhraní (GUI)

- V menu aplikací spusť **Killswitch Manager**

### Terminálové rozhraní (CLI)

Spuštění příkazem:
```bash
sudo killswitch
```

### Spuštění bez instalace killswitch-manager.sh
```bash
sudo ./killswitch-manager.sh
```

### Spuštění bez instalace killswitch-gui.py
```bash
sudo ./killswitch-gui.py
```

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
