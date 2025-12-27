#!/bin/bash
set -e

# Atualiza sistema
apt-get update -y

# Instala dependências
apt-get install -y \
  ca-certificates \
  curl \
  gnupg \
  git

# Docker
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

# Permitir docker sem sudo
usermod -aG docker ubuntu

# Clonar repo
cd /home/ubuntu
git clone https://github.com/EriickHenriique/etl-brazilian-ecommerce.git
cd etl-brazilian-ecommerce

# Subir Airflow
docker compose up -d
