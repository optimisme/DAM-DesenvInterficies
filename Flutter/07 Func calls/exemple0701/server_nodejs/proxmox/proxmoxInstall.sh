#!/bin/bash
# Prepare the remote Proxmox container for this Node.js project.

set -euo pipefail

cleanup() {
  ssh-agent -k >/dev/null 2>&1 || true
}
trap cleanup EXIT

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.env"

USER=${1:-$DEFAULT_USER}
RSA_PATH=${2:-"$DEFAULT_RSA_PATH"}
MYSQL_USER=${3:-super}
MYSQL_PASSWORD=${4:-1234}
RSA_PATH="${RSA_PATH%$'\r'}"

HOST="ieticloudpro.ieti.cat"
PORT_SSH="20127"
SSH_OPTS='-oHostKeyAlgorithms=+ssh-rsa -oPubkeyAcceptedAlgorithms=+ssh-rsa'

echo "This installation can take 40 minutes or longer."
echo "Wait until the script prints the final completion message and returns to your local shell."
read -r -p "Continue with the remote installation? [y/N] " CONFIRM
case "$CONFIRM" in
  [yY]|[yY][eE][sS]) ;;
  *)
    echo "Installation cancelled."
    exit 0
    ;;
esac

if [[ ! -f "$RSA_PATH" ]]; then
  echo "Error: No s'ha trobat la clau privada: $RSA_PATH"
  exit 1
fi

eval "$(ssh-agent -s)" >/dev/null
ssh-add "$RSA_PATH" >/dev/null

ssh -T -p "$PORT_SSH" $SSH_OPTS "$USER@$HOST" \
  sudo -n bash -s -- "$MYSQL_USER" "$MYSQL_PASSWORD" <<'EOF'
set -euo pipefail

MYSQL_USER="$1"
MYSQL_PASSWORD="$2"

export DEBIAN_FRONTEND=noninteractive

echo "==> Fixing apt/dpkg state if needed"
dpkg --configure -a || true
apt-get -f install -y || true
apt-get clean || true
apt-get update

echo "==> Removing Apache if installed"
systemctl stop apache2 >/dev/null 2>&1 || true
apt-get purge -y apache2 apache2-bin apache2-data apache2-utils || true
apt-get autoremove --purge -y || true
rm -rf /etc/apache2 /var/www /var/log/apache2 /var/lib/apache2

echo "==> Installing system packages"
apt-get update
apt-get install -y npm zip unzip rsync iproute2 iptables-persistent mysql-server

echo "==> Installing Node.js LTS with n"
sudo npm cache clean -f
sudo npm install -g n
sudo n lts
hash -r || true

echo "==> Installing pm2 globally"
npm install -g pm2

echo "==> Enabling MySQL"
systemctl enable mysql >/dev/null 2>&1 || true
systemctl start mysql

if [[ ! "$MYSQL_USER" =~ ^[A-Za-z0-9_]+$ ]]; then
  echo "Error: MySQL user can only contain letters, numbers, and underscores."
  exit 1
fi

MYSQL_PASSWORD_SQL=${MYSQL_PASSWORD//\\/\\\\}
MYSQL_PASSWORD_SQL=${MYSQL_PASSWORD_SQL//\'/\'\'}

echo "==> Creating/updating MySQL user '${MYSQL_USER}'@'localhost'"
mysql --batch --skip-column-names --execute "
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'localhost' IDENTIFIED WITH caching_sha2_password BY '${MYSQL_PASSWORD_SQL}';
ALTER USER '${MYSQL_USER}'@'localhost' IDENTIFIED WITH caching_sha2_password BY '${MYSQL_PASSWORD_SQL}';
GRANT ALL PRIVILEGES ON *.* TO '${MYSQL_USER}'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
"

echo "==> Installed versions"
node --version
npm --version
pm2 --version
mysql --version

echo "✔ Remote Proxmox install completed."
EOF
