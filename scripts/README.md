# Scripts Repository

Deze repository bevat verschillende bash-scripts voor het beheren van servers en netwerken. Hieronder volgt een overzicht van de beschikbare scripts, hun functies en gebruiksinstructies.

## Beschikbare Scripts

- [setup_pubkeys.sh](#setup_pubkeyssh)
- [script_naam-2.sh](#sjabloon-voor-toekomstige-scripts)

## setup_pubkeys.sh

### Beschrijving
Het script `setup_pubkeys.sh` is ontworpen om SSH-sleutels te genereren, deze naar meerdere servers te kopiëren en ervoor te zorgen dat de SSH-configuratie op deze servers correct is ingesteld voor pubkey-authenticatie. [Zie Disclaimer](#disclaimer)

### Functies
- **Genereren van SSH-sleutels**: Controleert of er al SSH-sleutels aanwezig zijn op de lokale machine. Indien niet, genereert het nieuwe sleutels.
- **Pingen van servers**: Controleert of de opgegeven servers bereikbaar zijn via ping.
- <span style="color: red;">**Configureren van SSH op servers**: Zorgt ervoor dat pubkey-authenticatie is ingeschakeld en herstart de SSH-dienst op de doelservers. </span> [Zie Dislaimer](#disclaimer)
- **Kopiëren van SSH-sleutels**: Kopieert de gegenereerde SSH-sleutels naar de doelservers.
- **Bijwerken van /etc/hosts**: Voegt de IP-adressen en hostnamen van de doelservers toe aan het lokale `/etc/hosts` bestand voor DNS-resolving.

### Gebruik
1. Clone de repository naar je lokale machine:
    ```bash
    git clone https://github.com/THectic-NL/Team-Building-Challenge-24.git
    cd 24/scripts
    ```

2. Maak het script uitvoerbaar:
    ```bash
    chmod +x setup_pubkeys.sh
    ```

3. Voer het script uit met root-privileges:
    ```bash
    sudo ./setup_pubkeys.sh
    ```

4. Volg de instructies in het script om de SSH-sleutels te genereren, te kopiëren en de configuratie te voltooien.

### Handig Voor
- Snel en efficiënt SSH-sleutels willen configureren op meerdere servers.
- <span style="color: red;">Situaties waarin SSH-pubkey-authenticatie moet worden ingeschakeld op een netwerk van servers.</span> [Zie Disclaimer](#disclaimer)
- Automatisering van serverbeheer taken om handmatige configuratie te minimaliseren.

## Disclaimer
Momenteel werkt het [setup_pubkeys.sh](setup_pubkeys.sh) script nog niet helemaal naar behoren. De known issues zijn:
- Issue # 1 Het script faalt erin om de /etc/ssh/sshd.config aan te passen en om hier de pubkeyauthentication op "yes" te zetten. Dit zal de gebruiker zelf nog even handmatig moeten doen.
----
Einde.

---

## Sjabloon voor toekomstige scripts

### script_name.sh

#### Beschrijving
Een korte beschrijving van wat het script doet.

#### Functies
- **Functie 1**: Beschrijving van de functie.
- **Functie 2**: Beschrijving van de functie.
- **Functie 3**: Beschrijving van de functie.

#### Gebruik
1. Clone de repository naar je lokale machine:
    ```bash
    git clone <repository-url>
    cd <repository-directory>
    ```

2. Maak het script uitvoerbaar:
    ```bash
    chmod +x script_name.sh
    ```

3. Voer het script uit met de benodigde privileges:
    ```bash
    ./script_name.sh
    ```

4. Volg de instructies in het script om de taken te voltooien.

#### Handig Voor
- Specifieke situaties waarin het script nuttig is.
- Doelgroepen die het script kunnen gebruiken.
- Specifieke taken die het script automatiseert.

---
