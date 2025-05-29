#!/bin/bash
# Script para restaurar backup do Alfresco Community 7.4
# Autor: João Vitor

BACKUP_DIR="/mnt/alfresco-backups"
INSTALL_DIR="/opt/alfresco/docker-compose"
DATA_DIR="$INSTALL_DIR/data/alf-repo-data"

echo "==== Restauração do Alfresco ===="

# Lista backups disponíveis
echo "📂 Backups disponíveis:"
ls -1 $BACKUP_DIR
echo ""

read -p "📦 Digite o nome do diretório de backup (ex: backup-2025-04-24_12-00): " BACKUP_FOLDER
FULL_BACKUP_PATH="$BACKUP_DIR/$BACKUP_FOLDER"

if [ ! -d "$FULL_BACKUP_PATH" ]; then
  echo "❌ Diretório de backup não encontrado: $FULL_BACKUP_PATH"
  exit 1
fi

# Para containers
echo "⛔ Parando containers..."
cd $INSTALL_DIR || { echo "❌ Falha ao acessar $INSTALL_DIR"; exit 1; }
docker-compose down

# Restaura dados do repositório
echo "🗂️ Restaurando dados do repositório..."
rm -rf "$DATA_DIR"/*
tar -xzf "$FULL_BACKUP_PATH/alfdata.tar.gz" -C "$DATA_DIR"

# Sobe somente o PostgreSQL
echo "🧠 Subindo banco de dados PostgreSQL..."
docker-compose up -d postgres
sleep 10  # Aguarda o banco subir

# Identifica o nome real do container PostgreSQL
POSTGRES_CONTAINER=$(docker ps --filter "name=postgres" --format "{{.Names}}" | head -n1)

if [ -z "$POSTGRES_CONTAINER" ]; then
  echo "❌ Container PostgreSQL não encontrado após subida!"
  exit 1
fi

# Restaura o banco
echo "🔄 Restaurando base de dados no container $POSTGRES_CONTAINER..."
docker exec -i "$POSTGRES_CONTAINER" psql -U alfresco alfresco < "$FULL_BACKUP_PATH/alfresco_postgres.sql"
if [ $? -ne 0 ]; then
  echo "❌ Falha ao restaurar o banco de dados!"
  exit 1
fi

# Restaura módulos customizados
echo "📦 Restaurando módulos customizados..."
tar -xzf "$FULL_BACKUP_PATH/alfresco.module.tar.gz" -C "$INSTALL_DIR"
tar -xzf "$FULL_BACKUP_PATH/share.module.tar.gz" -C "$INSTALL_DIR"

# Restaura índices Solr (se existir)
if [ -f "$FULL_BACKUP_PATH/solr.tar.gz" ]; then
  echo "🔎 Restaurando índices Solr..."
  tar -xzf "$FULL_BACKUP_PATH/solr.tar.gz" -C "$INSTALL_DIR/data/"
fi

# Sobe o ambiente completo
echo "🚀 Subindo containers completos..."
docker-compose up -d

echo "✅ Restauração concluída com sucesso!"
