#!/bin/bash

# Functies voor kleurgecodeerde echo
function rode_echo() { echo -e "\e[31m$1\e[0m"; }
function groene_echo() { echo -e "\e[32m$1\e[0m"; }
function lichtblauwe_echo() { echo -e "\e[36m$1\e[0m"; }

# Functie om foutmeldingen weer te geven en af te sluiten
function fout() {
  rode_echo "Fout: $1" >&2
  exit 1
}

# Controleer of het script als root wordt uitgevoerd
if [ "$EUID" -ne 0 ]; then
  fout "Dit script moet als root worden uitgevoerd. Log in als root en probeer opnieuw."
fi

# Controleer of het script niet met sudo wordt uitgevoerd
if [ ! -z "$SUDO_USER" ]; then
  fout "Dit script mag niet met sudo worden uitgevoerd. Log in als root en probeer opnieuw."
fi

# Controleer of vereiste commando's beschikbaar zijn
vereiste_commandos=(curl ssh ssh-keygen ssh-copy-id ping)
for cmd in "${vereiste_commandos[@]}"; do
  if ! command -v $cmd &> /dev/null; then
    fout "$cmd is niet geïnstalleerd. Installeer $cmd en probeer opnieuw."
  fi
done

# Paden en variabelen
gitlab_runner_binary="/usr/local/bin/gitlab-runner"
gitlab_runner_url="https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-amd64"
gitlab_runner_config="/etc/gitlab-runner"
ssh_key_file="/root/.ssh/id_rsa"

# Controleer of het systeem al een GitLab Runner is
function check_bestaande_gitlab_runner() {
  if [ -f "$gitlab_runner_binary" ] && [ -d "$gitlab_runner_config" ]; then
    lichtblauwe_echo "Waarschuwing: Dit systeem is al een GitLab Runner. Door dit script uit te voeren wordt de bestaande configuratie overschreven."
    echo -e "\e[36mWil je doorgaan met het overschrijven van de bestaande GitLab Runner configuratie? (ja/nee): \e[0m"
    read antwoord
    if [ "$antwoord" != "ja" ]; then
      fout "Script beëindigd op verzoek van de gebruiker."
    fi
  fi
}

# Functie om de bestaande GitLab Runner en gerelateerde configuraties te verwijderen
function verwijder_gitlab_runner() {
  lichtblauwe_echo "Verwijder de bestaande GitLab Runner en gerelateerde configuraties..."

  local runners=(
    "$gitlab_runner_binary"
    "/usr/bin/gitlab-runner"
    "/usr/local/bin/gitlab-runner"
    "/usr/sbin/gitlab-runner"
    "/sbin/gitlab-runner"
    "/bin/gitlab-runner"
  )

  for runner in "${runners[@]}"; do
    if [ -f "$runner" ]; then
      "$runner" uninstall || rode_echo "Kon de GitLab runner niet verwijderen van $runner."
      sudo rm -rf "$runner" || rode_echo "Kon de GitLab runner binaire niet verwijderen van $runner."
    fi
  done

  sudo rm -rf "$gitlab_runner_config" || rode_echo "Kon de GitLab runner configuraties niet verwijderen."
}

# Functie om de GitLab Runner te installeren
function installeer_gitlab_runner() {
  lichtblauwe_echo "Installeer de GitLab Runner opnieuw..."
  curl -L --output "$gitlab_runner_binary" "$gitlab_runner_url" || fout "Kon GitLab Runner niet downloaden."
  chmod +x "$gitlab_runner_binary" || fout "Kon GitLab Runner niet uitvoerbaar maken."
  "$gitlab_runner_binary" install --user=root --working-directory="/root" || fout "Kon de GitLab runner niet installeren."
  groene_echo "GitLab Runner succesvol geïnstalleerd."
}

# Functie om de GitLab Runner service te starten
function start_gitlab_runner_service() {
  lichtblauwe_echo "Start de GitLab Runner service..."
  "$gitlab_runner_binary" start || fout "Kon de GitLab runner service niet starten."
  groene_echo "GitLab Runner service succesvol gestart."
}

# Functie om de GitLab runner te registreren
function registreer_gitlab_runner() {
  lichtblauwe_echo "Voer de GitLab runner auth token in:"
  read auth_token
  if [ -z "$auth_token" ]; then
    fout "Auth token mag niet leeg zijn. Script wordt afgebroken."
  fi

  lichtblauwe_echo "Registreer de GitLab runner..."
  "$gitlab_runner_binary" register --url https://gitlab.com --token "$auth_token" --name "$(hostname)" --executor shell || fout "Kon de GitLab runner niet registreren."
  groene_echo "GitLab runner succesvol geregistreerd."
}

# Functie om SSH-sleutels te beheren
function beheer_ssh_sleutels() {
  mkdir -p /root/.ssh || fout "Kon .ssh directory niet maken."
  if [[ -f "${ssh_key_file}" && -f "${ssh_key_file}.pub" ]]; then
    lichtblauwe_echo "SSH-sleutels bestaan al."
    echo -e "\e[36mWil je de bestaande SSH-sleutels gebruiken of nieuwe genereren? (gebruiken/genereren): \e[0m"
    read keuze
    case $keuze in
      gebruiken)
        groene_echo "Bestaande SSH-sleutels worden gebruikt."
        ;;
      genereren)
        rm -f ${ssh_key_file}* || fout "Kon oude SSH-sleutels niet verwijderen"
        ssh-keygen -t rsa -b 4096 -f "$ssh_key_file" -N "" || fout "SSH-sleutels konden niet worden gegenereerd."
        groene_echo "Nieuwe SSH-sleutels gegenereerd."
        ;;
      *)
        fout "Ongeldige keuze. Script wordt afgebroken."
        ;;
    esac
  else
    # Genereren van nieuwe SSH-sleutels
    lichtblauwe_echo "Genereren van nieuwe SSH-sleutels..."
    ssh-keygen -t rsa -b 4096 -f "$ssh_key_file" -N "" || fout "SSH-sleutels konden niet worden gegenereerd."
    groene_echo "SSH-sleutels gegenereerd."
  fi

  # Lees de publieke sleutel
  pub_key=$(cat "${ssh_key_file}.pub")

  # Geef instructies voor het toevoegen van de sleutel aan GitLab
  lichtblauwe_echo "Instructies om de SSH-sleutel toe te voegen aan je GitLab repository deploy keys:"
  echo -e "\e[33m1. Open je webbrowser en ga naar je GitLab project.\e[0m"
  echo -e "\e[33m2. Navigeer naar 'Settings' > 'Repository' > 'Deploy Keys'.\e[0m"
  echo -e "\e[33m3. Klik op 'New deploy key'.\e[0m"
  echo -e "\e[33m4. Geef de key een titel zoals '$(hostname)'.\e[0m"
  echo -e "\e[33m5. Kopieer de onderstaande SSH-sleutel en plak deze in het 'Key' veld.\e[0m"
  echo -e "\e[32m$pub_key\e[0m"
  echo -e "\e[33m6. Selecteer 'Write access allowed' als de sleutel schrijfrechten nodig heeft.\e[0m"
  echo -e "\e[33m7. Klik op 'Add key' om de sleutel toe te voegen.\e[0m"
  echo -e "\e[36mDruk op Enter om door te gaan nadat je de sleutel hebt toegevoegd...\e[0m"
  read

  # Test de SSH-verbinding
  lichtblauwe_echo "Testen van GitLab SSH verbinding..."
  if ssh -T git@gitlab.com | grep -q "Welcome to GitLab"; then
    groene_echo "SSH-verbinding succesvol. Je bent klaar om te pullen en pushen."
  else
    fout "SSH-verbinding mislukt. Controleer of de sleutel correct is toegevoegd aan GitLab."
  fi
}

# Functie om servers te pingen en de bereikbaarheid te testen
function ping_servers() {
  declare -A backend_servers=(
    ["back-end01"]="192.168.30.120"
    ["back-end02"]="192.168.30.125"
    ["back-end03"]="192.168.30.130"
  )

  declare -A frontend_servers=(
    ["front-end01"]="192.168.30.105"
    ["front-end02"]="192.168.30.110"
    ["front-end03"]="192.168.30.115"
  )

  load_balancer_ip="192.168.20.102"

  lichtblauwe_echo "Testen welke servers reageren op pings..."
  up_backend_servers=()
  up_frontend_servers=()
  for server in "${!backend_servers[@]}"; do
    ip=${backend_servers[$server]}
    if ping -c 1 "$ip" &> /dev/null; then
      groene_echo "$server ($ip): Reageert"
      up_backend_servers+=("$ip")
    else
      rode_echo "$server ($ip): Reageert niet"
    fi
  done

  for server in "${!frontend_servers[@]}"; do
    ip=${frontend_servers[$server]}
    if ping -c 1 "$ip" &> /dev/null; then
      groene_echo "$server ($ip): Reageert"
      up_frontend_servers+=("$ip")
    else
      rode_echo "$server ($ip): Reageert niet"
    fi
  done

  if ping -c 1 "$load_balancer_ip" &> /dev/null; then
    groene_echo "load-balancer01 ($load_balancer_ip): Reageert"
  else
    rode_echo "load-balancer01 ($load_balancer_ip): Reageert niet"
  fi
}

# Functie om SSH-sleutels naar de servers te kopiëren en configureren
function configureer_ssh_op_servers() {
  for ip in "${up_backend_servers[@]}"; do
    lichtblauwe_echo "Voor server $ip, voer de volgende stappen uit:"
    echo -e "\e[36m1. Controleer of de SSH-configuratie correct is ingesteld om root login toe te staan:\e[0m"
    echo "   sudo nano /etc/ssh/sshd_config"
    echo -e "\e[36m2. Zoek naar de regel 'PermitRootLogin' en zorg ervoor dat deze is ingesteld op 'yes':\e[0m"
    echo "   PermitRootLogin yes"
    echo -e "\e[36m3. Herstart de SSH-dienst:\e[0m"
    echo "   sudo systemctl restart sshd"
    echo -e "\e[36m4. De publieke sleutel wordt nu automatisch gekopieerd naar de server $ip:\e[0m"
    ssh-copy-id -i /root/.ssh/id_rsa.pub root@$ip || fout "Kon de SSH-sleutel niet kopiëren naar $ip"
    groene_echo "Publieke sleutel succesvol gekopieerd naar $ip."
  done

  for ip in "${up_frontend_servers[@]}"; do
    lichtblauwe_echo "Voor server $ip, voer de volgende stappen uit:"
    echo -e "\e[36m1. Controleer of de SSH-configuratie correct is ingesteld om root login toe te staan:\e[0m"
    echo "   sudo nano /etc/ssh/sshd_config"
    echo -e "\e[36m2. Zoek naar de regel 'PermitRootLogin' en zorg ervoor dat deze is ingesteld op 'yes':\e[0m"
    echo "   PermitRootLogin yes"
    echo -e "\e[36m3. Herstart de SSH-dienst:\e[0m"
    echo "   sudo systemctl restart sshd"
    echo -e "\e[36m4. De publieke sleutel wordt nu automatisch gekopieerd naar de server $ip:\e[0m"
    ssh-copy-id -i /root/.ssh/id_rsa.pub root@$ip || fout "Kon de SSH-sleutel niet kopiëren naar $ip"
    groene_echo "Publieke sleutel succesvol gekopieerd naar $ip."
  done

  if ping -c 1 "$load_balancer_ip" &> /dev/null; then
    lichtblauwe_echo "Voor server $load_balancer_ip, voer de volgende stappen uit:"
    echo -e "\e[36m1. Controleer of de SSH-configuratie correct is ingesteld om root login toe te staan:\e[0m"
    echo "   sudo nano /etc/ssh/sshd_config"
    echo -e "\e[36m2. Zoek naar de regel 'PermitRootLogin' en zorg ervoor dat deze is ingesteld op 'yes':\e[0m"
    echo "   PermitRootLogin yes"
    echo -e "\e[36m3. Herstart de SSH-dienst:\e[0m"
    echo "   sudo systemctl restart sshd"
    echo -e "\e[36m4. De publieke sleutel wordt nu automatisch gekopieerd naar de server $load_balancer_ip:\e[0m"
    ssh-copy-id -i /root/.ssh/id_rsa.pub root@$load_balancer_ip || fout "Kon de SSH-sleutel niet kopiëren naar $load_balancer_ip"
    groene_echo "Publieke sleutel succesvol gekopieerd naar $load_balancer_ip."

    lichtblauwe_echo "Voer de volgende commando's uit op de load-balancer server:"
    ssh root@$load_balancer_ip "nginx -t && systemctl reload nginx && systemctl restart nginx && systemctl restart cloudflared" || fout "Kon de commando's niet uitvoeren op de load-balancer server."
    groene_echo "Commando's succesvol uitgevoerd op de load-balancer server."
  fi
}

# Functie om SSH-verbindingen naar de beschikbare servers te testen
function test_ssh_verbindingen() {
  lichtblauwe_echo "Testen van SSH-verbindingen naar de beschikbare servers..."
  for ip in "${up_backend_servers[@]}"; do
    ssh -o StrictHostKeyChecking=no -o BatchMode=yes root@$ip "echo 'Succesvol verbonden met $ip'" && groene_echo "Wachtwoordloze SSH verbinding werkt met $ip" || rode_echo "SSH verbinding met $ip faalde"
  done

  for ip in "${up_frontend_servers[@]}"; do
    ssh -o StrictHostKeyChecking=no -o BatchMode=yes root@$ip "echo 'Succesvol verbonden met $ip'" && groene_echo "Wachtwoordloze SSH verbinding werkt met $ip" || rode_echo "SSH verbinding met $ip faalde"
  done
}

# Functie voor functie alles uitvoeren
check_bestaande_gitlab_runner
verwijder_gitlab_runner
installeer_gitlab_runner
start_gitlab_runner_service
registreer_gitlab_runner
beheer_ssh_sleutels
ping_servers
configureer_ssh_op_servers
test_ssh_verbindingen

lichtblauwe_echo "Script voltooid."
