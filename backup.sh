#!/bin/bash

# Backup Script for Alfresco Community (adaptado)
# Autor original: @ambientelivre | Adaptado por João Vitor & Ajuda do GPT :P
# Requisitos: acesso ao diretório /mnt/alfresco-backups já montado via NFS

# Configurações
BACKUP_DIR="/mnt/alfresco-backups"
DATE_NOW=$(date +%Y-%m-%d_%H-%M)
INSTALL_DIR="/opt/docker-compose"
ALF_DATA="${INSTALL_DIR}/data/alf-repo-data"
DBENGINE="postgres"         # ou "mariadb"
INDEXBACKUP=true          # backup do Solr: true/false
LOG_FILE="${BACKUP_DIR}/backup_${DATE_NOW}.log"

# Configuração do PostgreSQL
PGUSER="alfresco"
PGPASSWORD="alfresco"
PGHOST="localhost"
PGDATABASE="alfresco"

# Configuração do MariaDB
#DBUSER="alfresco"
#DBPASS="alfresco"
#DBHOST="localhost"
#DBDATABASE="alfresco"

# Verifica se diretório de backup está disponível
if ! mountpoint -q "$BACKUP_DIR"; then
  echo "[ERRO] Diretório de backup não está montado: $BACKUP_DIR"
  exit 1
fi

# Cria subdiretório para este backup
BACKUP_PATH="${BACKUP_DIR}/backup-${DATE_NOW}"
mkdir -p "$BACKUP_PATH"

echo "[INFO] Iniciando backup em $DATE_NOW" | tee -a "$LOG_FILE"

# Dump do banco de dados
if [ "$DBENGINE" == "postgres" ]; then
  echo "[INFO] Realizando dump do PostgreSQL..." | tee -a "$LOG_FILE"
  docker-compose exec postgres pg_dump -U "$PGUSER" "$PGDATABASE" > "$BACKUP_PATH/alfresco_postgres.sql"
elif [ "$DBENGINE" == "mariadb" ]; then
  echo "[INFO] Realizando dump do MariaDB..." | tee -a "$LOG_FILE"
  docker-compose exec mariadb mysqldump -u"$DBUSER" -p"$DBPASS" "$DBDATABASE" > "$BACKUP_PATH/alfresco_mariadb.sql"
else
  echo "[ERRO] DBENGINE inválido: $DBENGINE" | tee -a "$LOG_FILE"
  exit 2
fi

# Backup do conteúdo
echo "[INFO] Compactando alf-repo-data..." | tee -a "$LOG_FILE"
tar -czf "$BACKUP_PATH/alfdata.tar.gz" -C "$ALF_DATA" .

# Backup dos módulos/customizações
echo "[INFO] Compactando módulos do Alfresco..." | tee -a "$LOG_FILE"
tar -czf "$BACKUP_PATH/alfresco.module.tar.gz" -C "$INSTALL_DIR" alfresco
tar -czf "$BACKUP_PATH/share.module.tar.gz" -C "$INSTALL_DIR" share

# Backup do docker-compose.yml
cp "$INSTALL_DIR/docker-compose.yml" "$BACKUP_PATH/"

# Backup do índice Solr, se habilitado
if [ "$INDEXBACKUP" == "true" ]; then
  echo "[INFO] Compactando índice Solr..." | tee -a "$LOG_FILE"
  tar -czf "$BACKUP_PATH/solr.tar.gz" -C "$INSTALL_DIR/data" solr-data
fi

echo "[OK] Backup concluído em $DATE_NOW" | tee -a "$LOG_FILE"
