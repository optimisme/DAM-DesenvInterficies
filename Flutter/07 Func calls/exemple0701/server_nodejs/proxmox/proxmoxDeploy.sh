#!/bin/bash
# Sends the project to the remote server with rsync and restarts the NodeJS app

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
REMOTE_DIR="nodejs_server"

# The project is the parent folder of "proxmox"
PROJECT_DIR="$(cd .. && pwd)"

if [[ ! -f "$RSA_PATH" ]]; then
  echo "Error: No s'ha trobat la clau privada: $RSA_PATH"
  exit 1
fi

if [[ ! -f "$PROJECT_DIR/package.json" ]]; then
  echo "Error: no trobo package.json a $PROJECT_DIR"
  exit 1
fi

if ! command -v rsync >/dev/null 2>&1; then
  echo "Error: cal instal·lar 'rsync' al vostre ordinador (sudo apt install rsync)"
  exit 1
fi

eval "$(ssh-agent -s)" >/dev/null
ssh-add "$RSA_PATH" >/dev/null

# The remote server also needs rsync, and the destination folder must exist
if ! ssh -T -p "$PORT_SSH" $SSH_OPTS "$USER@$HOST" \
  "command -v rsync >/dev/null 2>&1 && mkdir -p \"\$HOME/$REMOTE_DIR\""; then
  echo "Error: no s'ha pogut connectar, o el servidor remot no té 'rsync' instal·lat."
  echo "Al servidor remot (./proxmoxConnect.sh): sudo apt install rsync"
  exit 1
fi

# Send only the files that changed.
# Excluded files are never sent, and are never deleted from the remote server,
# so 'node_modules', 'data' and 'settings.env' are kept between deploys.
echo "Enviant arxius a $USER@$HOST:~/$REMOTE_DIR ..."
rsync -az --delete \
  -e "ssh -p $PORT_SSH $SSH_OPTS" \
  --exclude '/proxmox/' \
  --exclude '/node_modules/' \
  --exclude '/data/' \
  --exclude '/settings.env' \
  --exclude '/keys.env' \
  --exclude '/server-package.zip' \
  --exclude '.git/' \
  --exclude '.gitignore' \
  --exclude '.DS_Store' \
  "$PROJECT_DIR/" "$USER@$HOST:$REMOTE_DIR/"

ssh -T -p "$PORT_SSH" $SSH_OPTS "$USER@$HOST" \
  bash -s -- "$SERVER_PORT" "$REMOTE_DIR" << 'EOF'
set -e

SERVER_PORT="$1"
APP_DIR="$HOME/$2"
REMOTE_USER="$(id -un)"

export PATH="$HOME/.npm-global/bin:/usr/local/bin:$PATH"

cd "$APP_DIR"
test -f package.json

# Install dependencies while the old version keeps running
npm install --omit=dev

# Stop only our app
pm2 delete app >/dev/null 2>&1 || true

# Wait for port to be free
for i in {1..10}; do
  ss -tln | grep -q ":$SERVER_PORT " && sleep 1 || break
done

# Start app with PM2
pm2 start server/app.js --name app --update-env
pm2 save

# Configure PM2 to restart the app after a machine reboot
if command -v systemctl >/dev/null 2>&1; then
  if sudo -n true 2>/dev/null; then
    sudo env PATH="$PATH" pm2 startup systemd -u "$REMOTE_USER" --hp "$HOME"
    pm2 save
    echo "✔️  PM2 configurat per iniciar-se automàticament després d'un reinici."
  else
    echo "⚠️  Deploy correcte, però no s'ha pogut configurar l'arrencada automàtica."
    echo "⚠️  Cal executar manualment al servidor:"
    echo "sudo env PATH=$PATH pm2 startup systemd -u $REMOTE_USER --hp $HOME"
    echo "pm2 save"
  fi
else
  echo "⚠️  No s'ha trobat systemd. No s'ha configurat l'arrencada automàtica amb PM2."
fi

echo "✔️  Deploy correcte. Estat PM2:"
pm2 status
EOF
