#!/bin/bash
# Builds the Java server (.jar) with Maven, sends it to the remote server and restarts it

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

# The project is the parent folder of "proxmox"
PROJECT_DIR="$(cd .. && pwd)"
JAR_PATH="$PROJECT_DIR/target/$JAR_NAME"

if [[ ! -f "$RSA_PATH" ]]; then
  echo "Error: No s'ha trobat la clau privada: $RSA_PATH"
  exit 1
fi

if [[ ! -f "$PROJECT_DIR/pom.xml" ]]; then
  echo "Error: no trobo pom.xml a $PROJECT_DIR"
  exit 1
fi

if ! command -v mvn >/dev/null 2>&1; then
  echo "Error: cal tenir 'Maven' (mvn) instal·lat al vostre ordinador"
  exit 1
fi

echo "Generant $JAR_NAME amb Maven..."
rm -f "$JAR_PATH"
(cd "$PROJECT_DIR" && mvn -q clean package -Dmaven.test.skip=true)

if [[ ! -f "$JAR_PATH" ]]; then
  echo "Error: Maven no ha generat l'arxiu: $JAR_PATH"
  exit 1
fi

eval "$(ssh-agent -s)" >/dev/null
ssh-add -q "$RSA_PATH"

# The remote server needs Java to run the .jar
if ! ssh -T -p "$PORT_SSH" $SSH_OPTS "$USER@$HOST" "command -v java >/dev/null 2>&1"; then
  echo "Error: no s'ha pogut connectar, o el servidor remot no té 'java' instal·lat."
  echo "Al servidor remot (./proxmoxConnect.sh): sudo apt install openjdk-21-jre-headless"
  exit 1
fi

# Sent with a temporary name, it replaces the old .jar once the old server is stopped
echo "Enviant $JAR_NAME a $USER@$HOST ..."
scp -q -P "$PORT_SSH" $SSH_OPTS "$JAR_PATH" "$USER@$HOST:$JAR_NAME.new"

ssh -T -p "$PORT_SSH" $SSH_OPTS "$USER@$HOST" \
  bash -s -- "$SERVER_PORT" "$JAR_NAME" "$SERVICE_NAME" << 'EOF'
set -e

SERVER_PORT="$1"
JAR_NAME="$2"
SERVICE="$3"
REMOTE_USER="$(id -un)"
JAVA_BIN="$(command -v java)"
UNIT="/etc/systemd/system/$SERVICE.service"
LOG="$HOME/output.log"

HAS_SUDO=0
sudo -n true 2>/dev/null && HAS_SUDO=1
HAS_SYSTEMD=0
[ -d /run/systemd/system ] && command -v systemctl >/dev/null 2>&1 && HAS_SYSTEMD=1

port_busy() {
  if command -v ss >/dev/null 2>&1; then
    ss -tln | grep -q ":$SERVER_PORT "
  else
    netstat -tln 2>/dev/null | grep -q ":$SERVER_PORT "
  fi
}

# Stop the old server: the service, and any process started by hand or by older scripts
if [ -f "$UNIT" ] && [ "$HAS_SUDO" = 1 ]; then
  sudo systemctl stop "$SERVICE" 2>/dev/null || true
fi
pkill -f "java -jar $JAR_NAME" 2>/dev/null || true
for i in {1..10}; do
  pgrep -f "java -jar $JAR_NAME" >/dev/null 2>&1 || break
  sleep 1
done
pkill -9 -f "java -jar $JAR_NAME" 2>/dev/null || true

# Wait for port to be free
for i in {1..10}; do
  port_busy && sleep 1 || break
done
if port_busy; then
  rm -f "$HOME/$JAR_NAME.new"
  echo "Error: el port $SERVER_PORT del servidor remot està ocupat per un altre programa:"
  (sudo -n ss -tlnp 2>/dev/null || ss -tln) | grep ":$SERVER_PORT " || true
  echo "Si és un servidor NodeJS (pm2), al servidor remot: pm2 delete app && pm2 save"
  exit 1
fi

mv "$HOME/$JAR_NAME.new" "$HOME/$JAR_NAME"
: > "$LOG"

if [ "$HAS_SUDO" = 1 ] && [ "$HAS_SYSTEMD" = 1 ]; then
  # A system service keeps the server running: it starts when the machine
  # boots and it is restarted if the program fails
  sudo tee "$UNIT" >/dev/null << UNIT_EOF
[Unit]
Description=Java server ($JAR_NAME)
After=network.target

[Service]
User=$REMOTE_USER
WorkingDirectory=$HOME
ExecStart=$JAVA_BIN -jar $JAR_NAME
SuccessExitStatus=143
Restart=on-failure
RestartSec=3
StandardOutput=append:$LOG
StandardError=append:$LOG

[Install]
WantedBy=multi-user.target
UNIT_EOF
  sudo systemctl daemon-reload
  sudo systemctl enable "$SERVICE" >/dev/null 2>&1
  sudo systemctl restart "$SERVICE"
  AUTOSTART=1
else
  cd "$HOME"
  setsid nohup "$JAVA_BIN" -jar "$JAR_NAME" >> "$LOG" 2>&1 < /dev/null &
  AUTOSTART=0
fi

# Check that the server really listens on its port
for i in {1..20}; do
  port_busy && break
  sleep 1
done
if ! port_busy; then
  echo "Error: el servidor no ha arrencat al port $SERVER_PORT. Últimes línies de $LOG:"
  tail -n 20 "$LOG" || true
  exit 1
fi

echo "✔️  Deploy correcte. Servidor Java funcionant al port $SERVER_PORT."
if [ "$AUTOSTART" = 1 ]; then
  echo "✔️  Servei '$SERVICE' configurat per iniciar-se automàticament després d'un reinici."
else
  echo "⚠️  No s'ha pogut configurar l'arrencada automàtica (cal 'sudo' sense contrasenya i systemd)."
  echo "⚠️  Si el servidor remot es reinicia, caldrà tornar a executar ./proxmoxDeploy.sh"
fi
echo "Missatges del servidor: $LOG"
EOF
