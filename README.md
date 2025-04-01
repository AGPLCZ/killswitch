# killswitch

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
