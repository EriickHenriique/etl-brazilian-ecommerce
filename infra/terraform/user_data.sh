#!/bin/bash
set -e

REPO_URL="https://github.com/EriickHenriique/etl-brazilian-ecommerce.git"
REPO_DIR="/home/ubuntu/etl-brazilian-ecommerce"

# Atualiza sistema
apt-get update -y

# Instala dependências
apt-get install -y ca-certificates curl gnupg git

# ---------------------------
# Criar SWAP de 2GB (t3.micro)
# ---------------------------
if ! swapon --show | grep -q '/swapfile'; then
  fallocate -l 2G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

# Docker repo + key
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo $VERSION_CODENAME) stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Garante que o Docker está rodando
systemctl enable --now docker

# Permitir docker sem sudo
usermod -aG docker ubuntu

# Clonar repo (se já existir, só atualiza)
if [ -d "$REPO_DIR/.git" ]; then
  cd "$REPO_DIR"
  git pull
else
  cd /home/ubuntu
  git clone "$REPO_URL"
fi

# Garantir dono do repo pro ubuntu
chown -R ubuntu:ubuntu "$REPO_DIR" || true

# Criar diretórios esperados pelo compose
mkdir -p "$REPO_DIR/dags" "$REPO_DIR/logs" "$REPO_DIR/plugins"

# UID do Airflow dentro do container
AIRFLOW_UID=50000

# Criar .env pro docker compose ler
cat > "$REPO_DIR/.env" <<EOF
AIRFLOW_UID=$AIRFLOW_UID
AIRFLOW_ADMIN_USER=admin
AIRFLOW_ADMIN_PASSWORD=admin
AIRFLOW_ADMIN_FIRSTNAME=Admin
AIRFLOW_ADMIN_LASTNAME=User
AIRFLOW_ADMIN_EMAIL=admin@example.com
EOF

# Ajustar permissões para o UID do Airflow
chown -R "$AIRFLOW_UID":0 "$REPO_DIR/dags" "$REPO_DIR/logs" "$REPO_DIR/plugins"

# Subir Airflow (init primeiro) como ubuntu
sudo -u ubuntu -H bash -lc "cd $REPO_DIR && docker compose up airflow-init"
sudo -u ubuntu -H bash -lc "cd $REPO_DIR && docker compose up -d"
