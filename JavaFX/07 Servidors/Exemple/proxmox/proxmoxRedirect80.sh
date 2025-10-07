#!/bin/bash
# Connect remote and redirect port 80 to $SERVER_PORT

source ./config.env

USER=${1:-$DEFAULT_USER}
RSA_PATH=${2:-"$DEFAULT_RSA_PATH"}
SERVER_PORT=${3:-$DEFAULT_SERVER_PORT}
RSA_PATH="${RSA_PATH%$'\r'}"
SSH_OPTS='-oHostKeyAlgorithms=+ssh-rsa -oPubkeyAcceptedAlgorithms=+ssh-rsa'

echo "User: $USER"
echo "Ruta RSA: $RSA_PATH"
echo "Server port: $SERVER_PORT"

if [[ ! -f "$RSA_PATH" ]]; then
  echo "Error: no troba la clau: $RSA_PATH"
  exit 1
fi

read -s -p "Pwd sudo remota: " SUDO_PASSWORD
echo

eval "$(ssh-agent -s)"
ssh-add "$RSA_PATH"

ssh -t -p 20127 $SSH_OPTS "$USER@ieticloudpro.ieti.cat" <<EOF
export DEBIAN_FRONTEND=noninteractive
echo "$SUDO_PASSWORD" | sudo -S apt-get update -qq
echo "$SUDO_PASSWORD" | sudo -S apt-get install -y iptables-persistent

COUNT=\$(echo "$SUDO_PASSWORD" | sudo -S iptables-save -t nat \
           | grep -c -- "--dport 80.*--to-ports $SERVER_PORT")
if [[ \$COUNT -eq 0 ]]; then
    echo "$SUDO_PASSWORD" | sudo -S iptables -t nat -A PREROUTING \
         -p tcp --dport 80 -j REDIRECT --to-ports $SERVER_PORT
    echo "$SUDO_PASSWORD" | sudo -S iptables-save > /tmp/rules.v4
    echo "$SUDO_PASSWORD" | sudo -S mv /tmp/rules.v4 /etc/iptables/rules.v4
    echo "$SUDO_PASSWORD" | sudo -S systemctl restart netfilter-persistent
    echo "Redirecció afegida i guardada."
else
    echo "Ja existeixen \$COUNT redireccions cap al port $SERVER_PORT."
fi

exit
EOF

ssh-agent -k
