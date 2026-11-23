#!/bin/bash
# Stops the Java server at the remote server.
# It stays stopped (also after a reboot) until the next ./proxmoxDeploy.sh

set -e

cleanup() {
  ssh-agent -k >/dev/null 2>&1 || true
}
trap cleanup EXIT

source ./config.env

USER=${1:-$DEFAULT_USER}
RSA_PATH=${2:-"$DEFAULT_RSA_PATH"}
SERVER_PORT=${3:-$DEFAULT_SERVER_PORT}
RSA_PATH="${RSA_PATH%$'\r'}"

HOST="ieticloudpro.ieti.cat"
PORT_SSH="20127"
SSH_OPTS='-oHostKeyAlgorithms=+ssh-rsa -oPubkeyAcceptedAlgorithms=+ssh-rsa -oUpdateHostKeys=no'
JAR_NAME="server-package.jar"
SERVICE_NAME="java-server"

if [[ ! -f "$RSA_PATH" ]]; then
  echo "Error: No s'ha trobat la clau privada: $RSA_PATH"
  exit 1
fi

eval "$(ssh-agent -s)" >/dev/null
ssh-add -q "$RSA_PATH"

ssh -T -p "$PORT_SSH" $SSH_OPTS "$USER@$HOST" \
  bash -s -- "$SERVER_PORT" "$JAR_NAME" "$SERVICE_NAME" << 'EOF'
set -e

SERVER_PORT="$1"
JAR_NAME="$2"
SERVICE="$3"
UNIT="/etc/systemd/system/$SERVICE.service"

# Stop the service and do not start it again when the machine boots
if [ -f "$UNIT" ] && sudo -n true 2>/dev/null; then
  sudo systemctl disable --now "$SERVICE" >/dev/null 2>&1 || true
fi

# Stop any process started by hand or by older scripts
if pgrep -f "java -jar $JAR_NAME" >/dev/null 2>&1; then
  pkill -f "java -jar $JAR_NAME" 2>/dev/null || true
  for i in {1..10}; do
    pgrep -f "java -jar $JAR_NAME" >/dev/null 2>&1 || break
    sleep 1
  done
  pkill -9 -f "java -jar $JAR_NAME" 2>/dev/null || true
fi

if pgrep -f "java -jar $JAR_NAME" >/dev/null 2>&1; then
  echo "Error: no s'ha pogut aturar el servidor Java."
  exit 1
fi

echo "✔️  Servidor Java aturat. No tornarà a arrencar fins al proper ./proxmoxDeploy.sh"
EOF
