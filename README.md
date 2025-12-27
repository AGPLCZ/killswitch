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

- nebude třeba zadávat heslo před vypnutím

```bash
sudo visudo
```

### Vlož
```bash
username ALL = NOPASSWD: /sbin/poweroff
username ALL = NOPASSWD: /sbin/shutdown
```

### Klávesová zkratka
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

## ⚠️ Upozornění

Autor nenese odpovědnost za ztrátu neuložených dat způsobenou náhlým vypnutím  
počítače při testování nebo používání tohoto nástroje.

Používejte s rozumem.
