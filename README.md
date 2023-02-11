# CDN77 Test Assignment

### Usage
To deploy the whole infrastructure, simply execute
```bash
./run.sh
```

This will create a set of containers and an Ansible control machine.
The script will configure the containers, treated as separate servers, to communicate via ssh between each other.

To clean up everything, simply run
```bash
./stop.sh
```

### Initial Assignment

> Vasim cilem je vytvorit virtualni infrastrukturu zajistujici nektere elementarni ukony, ktere se v nasem prostredi vyskytuji. Nektere ukoly jsou navazujici, nektere lze preskocit a venovat se jinym. Task je koncipovan tak, aby zdet byla moznost prokazat znalost prakticky libovolne z nami pouzivanych technologii a zaroven aby vybizel k primerenemu studiu technologii novych. Je tudiz nepravdepodobne, ze se Vam podari dokoncit vse. Bonusove ukoly reste pouze pokud danou technologii znate a zaberou vam minimum casu.
>
>- 1\. Pomoci technologie typu Proxmox/KVM/Docker/LXC/… si vytvorte libovolny pocet virtulanich PC ci kontejneru zalozenych na OS Debian
>- 2\.Jednotlive VM/kontejnery pouzijte ke zprovozneni nasledujicich sluzeb
>  - 2.1\.Monitoring
>    - Pouzijte Prometheus a prislusne exportery ke sberu metrik z ostatnich VM/kontejneru
>    - BONUS: Data z libovolneho exporteru zobrazte v Grafana dashboardu
>    - BONUS2: Nastavte libovolne pravidlo pro Alertmanager na zaklade dat libovolneho exporteru
>  - nginx
>    - Prvni instanci nginxu nastavte jako web server hostujici soubory z lokalniho disku
>    - Druhou instanci nastavte jako reverzni, cacheujici proxy server, ktery vyuziva prvni nginx instanci jako svuj upstream
>    - BONUS: Pri komunikaci proxy <> upstream pouzijte keepalive connections
>    - BONUS2: Pri komunikaci proxy <> client pouzijte bezpecne nastavene SSL/TLS connections
>  - Alespon jeden distribuovany system z nize uvedeneho seznamu
>    - Kafka, Clickhouse, Etcd, Ceph, Citus, Cockroach, ELK, Zookeeper
>    - Zprovoznete cluster odolavajici vypadku 2 instanci sluzby
>  - Vlastni skript/program v libovolnem jazyce bezici jako daemon tj. na pozadi
>    - Pro udrzovani behu pouzijte daemontools
>    - BONUS deamontools: pouzijte integrovany multilog
>    - Spustte jej na jednom libovolnem predchozim vytvorenem VM/kontejneru
>    - Pouzijte jej k testovani funkcnosti jednotlivych zprovoznenych sluzeb periodickym zapisem nasledujicich stavovych informaci do souboru
>      - Monitoring: Metriku vyjadrujici load VMs/kontejneru
>      - VPN: IP v dany moment aktivnich klientu pripojenych do VPN
>      - nginx: Request/Response stub status modulu vcetne hlavicek
>    - Format zapisovanych dat necht je human readable a jednoduse strojove zpracovatelny
>
> Vytvoreni infrastruktury, setup jednotlivych sluzeb, atd by melo byt plne automatizovane pomoci Ansible a odevzdane jako GitHub repozitar obsahujici jednotlive Ansible playbooky. Playbooky by mely byt ve stavu pripravem ke spusteni pro jednoduchou replikaci cele infrastruktury a overeni funkcionality jednotlivych sluzeb. Pri neznalosti Ansible odevzdejte napr. bash scripty replikujici vasi cinnost - pri tvorbe skriptu se zamerte na stejne pozadavky jako v pripade odevzdavani Ansible playbooku.
