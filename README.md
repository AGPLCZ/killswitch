# Killswitch Manager v0.2

**Killswitch Manager** je jednoduchý terminálový nástroj pro Linux (Ubuntu), který umožňuje snadno a rychle:

- vytvořit **USB killswitch** – vypnutí počítače po vytažení konkrétního USB zařízení (např. flashdisk),
- přidat více zařízení současně (pokročilý režim),
- přidat **klávesovou zkratku** pro okamžité vypnutí,
- zobrazit a spravovat aktivní pravidla,
- odstranit jedno nebo všechna zařízení,
- funguje i bez grafického rozhraní (čistý Bash skript, žádné závislosti).

---

## 🧩 Co to umí

- ✅ Přidat zařízení jako killswitch (USB odpojení = shutdown)
- ✅ Přehled aktivních zařízení
- ✅ Podpora více zařízení současně
- ✅ Hromadná deaktivace všech pravidel
- ✅ Přidání skriptu pro klávesovou zkratku
- ✅ Barevné přehledné menu (TUI)
- ✅ Funguje i offline / z Terminálu / z recovery prostředí

---

## 🛠️ Instalace

1. Stáhni soubor `killswitch-manager.sh`
2. Přidej práva ke spuštění:

```bash
chmod +x killswitch-manager.sh



# killswitch key - manuálně

- chmod +x setup_usb_killswitch.sh
- sudo ./setup_usb_killswitch.sh

### KILL KEY
- Zabrání vyskakování potvrzovacích oken a vypne počítač okamžitě) 
- sudo visudo

#### Vlož
- agpl ALL = NOPASSWD: /sbin/poweroff
- agpl ALL = NOPASSWD: /sbin/shutdown


#### vytvoř bash  kill.sh
- #!/bin/bash
- sudo poweroff -f


#### změna práv
- chmod +x ./killswitch.sh

# klávesová zkratka
- Ubuntu ->  nastavení -> klávesnice -> vlastní klávesové zkratky 
- /home/ag/kill.sh
