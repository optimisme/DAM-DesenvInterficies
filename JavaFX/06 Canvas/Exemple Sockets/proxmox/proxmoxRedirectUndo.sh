#!/bin/bash

source ./config.env

# Obtain configuration parameters
USER=${1:-$DEFAULT_USER}
RSA_PATH=${2:-"$DEFAULT_RSA_PATH"}
SERVER_PORT=${3:-$DEFAULT_SERVER_PORT}
RSA_PATH="${RSA_PATH%$'\r'}"  

echo "User: $USER"
echo "Ruta RSA: $RSA_PATH"
echo "Server port: $SERVER_PORT"

if [[ ! -f "${RSA_PATH}" ]]; then
  echo "Error: No s'ha trobat el fitxer de clau privada: $RSA_PATH"
  exit 1
fi

# Ask for the remote password
read -s -p "Introdueix la contrasenya de sudo per al servidor remot: " SUDO_PASSWORD
echo ""

# Start SSH agent
eval "$(ssh-agent -s)"
ssh-add "${RSA_PATH}"

# SSH to server and execute command with sudo, passing the password
ssh -t -p 20127 "$USER@ieticloudpro.ieti.cat" << EOF
    echo '$SUDO_PASSWORD' | sudo -S iptables -t nat -D PREROUTING -p tcp --dport 80 -j REDIRECT --to-port $SERVER_PORT
EOF

# Cleanup
ssh-agent -k
