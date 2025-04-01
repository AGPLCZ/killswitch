# Killswitch Manager v0.2

**Killswitch Manager** je jednoduchý terminálový nástroj pro Linux (Ubuntu).

## 🧩 Co to umí
- vytvořit **USB killswitch** – vypnutí počítače po vytažení konkrétního USB zařízení (např. flashdisk)
- přidat více zařízení současně
- přidat **klávesovou zkratku** pro okamžité vypnutí
- zobrazit a spravovat aktivní pravidla
- odstranit jedno nebo všechna zařízení
- funguje i bez grafického rozhraní (čistý Bash skript)

---

## 🛠️ Instalace

1. Stáhni soubor `killswitch-manager.sh`
2. Stáhni soubor `install.sh`
3. Přidej práva ke spuštění:

```bash
chmod +x killswitch-manager.sh
chmod +x install.sh
```
4. Sputit install.sh
5. Provést ruční nastavení KILL KEY pro vypínání klávesovou zkratkou

### KILL KEY
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
