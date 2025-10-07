#!/bin/bash
# Remove only NAT PREROUTING REDIRECT rules for destination port 80 and persist the remaining rules.

set -euo pipefail

source ./config.env

USER=${1:-$DEFAULT_USER}
RSA_PATH=${2:-"$DEFAULT_RSA_PATH"}
SERVER_PORT=${3:-$DEFAULT_SERVER_PORT}   # not strictly needed, we remove ALL 80 redirects
RSA_PATH="${RSA_PATH%$'\r'}"
SSH_OPTS='-oIdentitiesOnly=yes -oHostKeyAlgorithms=+ssh-rsa -oPubkeyAcceptedAlgorithms=+ssh-rsa'

echo "User: $USER"
echo "RSA:  $RSA_PATH"

if [[ ! -f "$RSA_PATH" ]]; then
  echo "Error: no troba la clau: $RSA_PATH"
  exit 1
fi

read -s -p "Pwd sudo remota: " SUDO_PASSWORD
echo

eval "$(ssh-agent -s)"
ssh-add "$RSA_PATH" >/dev/null

ssh -t -p 20127 $SSH_OPTS "$USER@ieticloudpro.ieti.cat" <<'EOF'
set -euo pipefail
read -r SUDO_PASSWORD
# List candidate rules (-A PREROUTING ... --dport 80 ... -j REDIRECT)
CANDIDATES=$(echo "\$SUDO_PASSWORD" | sudo -S iptables-save -t nat \
  | awk '
      BEGIN{inNat=0}
      /^\*nat/{inNat=1; next}
      /^COMMIT/{inNat=0}
      inNat && /\-A PREROUTING/ && /--dport 80/ && /-j REDIRECT/ {print}
    ')

if [[ -z "\$CANDIDATES" ]]; then
  echo "No hi ha redireccions de port 80 a eliminar."
else
  echo "Eliminant redireccions de port 80:"
  # Convert "-A PREROUTING ..." -> "-D PREROUTING ..." and execute
  while read -r LINE; do
    [[ -z "\$LINE" ]] && continue
    CMD=\$(echo "\$LINE" | sed 's/^-A PREROUTING/-D PREROUTING/')
    echo " - iptables -t nat \$CMD"
    echo "\$SUDO_PASSWORD" | sudo -S iptables -t nat \$CMD
  done <<< "\$CANDIDATES"
fi

# Persist full current rules (do NOT delete rules.v4 blindly)
TMP=/tmp/rules.v4
echo "\$SUDO_PASSWORD" | sudo -S iptables-save > "\$TMP"
echo "\$SUDO_PASSWORD" | sudo -S install -m 600 "\$TMP" /etc/iptables/rules.v4
echo "\$SUDO_PASSWORD" | sudo -S systemctl restart netfilter-persistent || true
echo "✔️  Redireccions del port 80 eliminades i configuració persistent actualitzada."
EOF
# send sudo pwd to remote stdin (first read)
# shellcheck disable=SC2183
<<<"$SUDO_PASSWORD"

ssh-agent -k >/dev/null
