#!/bin/bash

# Function for cleanup on script exit
cleanup() {
    local exit_code=$?
    echo "Performing cleanup..."
    [[ -n "$JAR_PATH" ]] && rm -f "$JAR_PATH"
    ssh-agent -k 2>/dev/null
    cd "$ORIGINAL_DIR" 2>/dev/null
    exit $exit_code
}
trap cleanup EXIT

# Emmagatzemar el directori original
ORIGINAL_DIR=$(pwd)

source ./config.env

# Obtenir configuració dels paràmetres
USER=${1:-$DEFAULT_USER}
RSA_PATH=${2:-"$DEFAULT_RSA_PATH"}
SERVER_PORT=${3:-$DEFAULT_SERVER_PORT}
RSA_PATH="${RSA_PATH%$'\r'}"

echo "User: $USER"
echo "Ruta RSA: $RSA_PATH"
echo "Server port: $SERVER_PORT"

JAR_NAME="server-package.jar"

cd ..

# Comprovem que el fitxer de clau privada existeix
if [[ ! -f "$RSA_PATH" ]]; then
    echo "Error: No s'ha trobat el fitxer de clau privada: $RSA_PATH"
    exit 1
fi

# Iniciar ssh-agent i carregar la clau temporal
eval "$(ssh-agent -s)"
ssh-add "${RSA_PATH}"

# SSH al servidor per trobar i matar el procés del JAR
ssh -t -p 20127 "$USER@ieticloudpro.ieti.cat" << EOF
    PID=\$(ps aux | grep 'java -jar $JAR_NAME' | grep -v 'grep' | awk '{print \$2}')
    if [ -n "\$PID" ]; then
      kill -15 \$PID
      echo "Senyal SIGTERM enviat al procés \$PID."
      for i in {1..10}; do
        if ! ps -p \$PID > /dev/null; then
          echo "Procés \$PID aturat correctament."
          break
        fi
        echo "Esperant que el procés finalitzi..."
        sleep 1
      done
      if ps -p \$PID > /dev/null; then
        echo "Procés \$PID encara actiu, forçant aturada..."
        kill -9 \$PID
      fi
    else
      echo "No s'ha trobat el procés $JAR_NAME."
    fi

    while netstat -an | grep -q ':$SERVER_PORT.*LISTEN'; do
      echo "Esperant que el port $SERVER_PORT es desalliberi..."
      sleep 1
    done
    echo "Port $SERVER_PORT desalliberat."
EOF
