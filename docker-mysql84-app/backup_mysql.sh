#!/bin/bash

# Docker MySQL Backup Script with Users and Grants
# Usage: ./backup_mysql.sh

CONTAINER_NAME="mysql_server"
BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d_%H%M%S)
MYSQL_ROOT_PASSWORD="rootSecurePass123!"

mkdir -p $BACKUP_DIR

echo "Starting MySQL backup at $(date)"

echo "Backing up all databases..."
docker exec $CONTAINER_NAME mysqldump \
    -u root \
    -p$MYSQL_ROOT_PASSWORD \
    --all-databases \
    --single-transaction \
    --routines \
    --triggers \
    --events \
    --set-gtid-purged=OFF \
    --flush-privileges > $BACKUP_DIR/all_databases_$DATE.sql

echo "Backing up users..."
docker exec $CONTAINER_NAME mysql \
    -u root \
    -p$MYSQL_ROOT_PASSWORD \
    --skip-column-names \
    -A \
    -e "SELECT CONCAT('SHOW CREATE USER ''',user,'''@''',host,''';') FROM mysql.user WHERE user NOT IN ('mysql.sys','mysql.session','mysql.infoschema')" \
    | docker exec -i $CONTAINER_NAME mysql \
    -u root \
    -p$MYSQL_ROOT_PASSWORD \
    --skip-column-names \
    -A \
    | sed 's/$/;/' > $BACKUP_DIR/users_$DATE.sql

echo "Backing up grants..."
docker exec $CONTAINER_NAME mysql \
    -u root \
    -p$MYSQL_ROOT_PASSWORD \
    --skip-column-names \
    -A \
    -e "SELECT CONCAT('SHOW GRANTS FOR ''',user,'''@''',host,''';') FROM mysql.user WHERE user NOT IN ('mysql.sys','mysql.session','mysql.infoschema')" \
    | docker exec -i $CONTAINER_NAME mysql \
    -u root \
    -p$MYSQL_ROOT_PASSWORD \
    --skip-column-names \
    -A \
    | sed 's/$/;/' > $BACKUP_DIR/grants_$DATE.sql

# Create restore script
cat > $BACKUP_DIR/restore_$DATE.sh <<'RESTORE_SCRIPT'
#!/bin/bash

# MySQL Restoration Script for Docker
# Usage: ./restore_YYYYMMDD_HHMMSS.sh

CONTAINER_NAME="mysql_server"
MYSQL_ROOT_PASSWORD="rootSecurePass123!"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATE_SUFFIX="${BASH_SOURCE[0]##*restore_}"
DATE_SUFFIX="${DATE_SUFFIX%.sh}"

echo "Starting MySQL restoration..."

# Wait for MySQL to be ready
echo "Waiting for MySQL to be ready..."
until docker exec $CONTAINER_NAME mysqladmin ping -u root -p$MYSQL_ROOT_PASSWORD --silent; do
    echo "Waiting for database connection..."
    sleep 2
done

# Restore all databases
echo "Restoring databases..."
docker exec -i $CONTAINER_NAME mysql -u root -p$MYSQL_ROOT_PASSWORD < "$SCRIPT_DIR/all_databases_$DATE_SUFFIX.sql"

# Restore users
echo "Restoring users..."
docker exec -i $CONTAINER_NAME mysql -u root -p$MYSQL_ROOT_PASSWORD < "$SCRIPT_DIR/users_$DATE_SUFFIX.sql"

# Restore grants
echo "Restoring grants..."
docker exec -i $CONTAINER_NAME mysql -u root -p$MYSQL_ROOT_PASSWORD < "$SCRIPT_DIR/grants_$DATE_SUFFIX.sql"

# Flush privileges
echo "Flushing privileges..."
docker exec $CONTAINER_NAME mysql -u root -p$MYSQL_ROOT_PASSWORD -e "FLUSH PRIVILEGES;"

echo "Restoration completed successfully!"
RESTORE_SCRIPT

chmod +x $BACKUP_DIR/restore_$DATE.sh

echo "Compressing backup..."
tar -czf $BACKUP_DIR/mysql_backup_$DATE.tar.gz \
    -C $BACKUP_DIR \
    all_databases_$DATE.sql \
    users_$DATE.sql \
    grants_$DATE.sql \
    restore_$DATE.sh

# Cleanpup
rm -f $BACKUP_DIR/all_databases_$DATE.sql \
      $BACKUP_DIR/users_$DATE.sql \
      $BACKUP_DIR/grants_$DATE.sql \
      $BACKUP_DIR/restore_$DATE.sh

echo "Backup completed: mysql_backup_$DATE.tar.gz"
ls -lh $BACKUP_DIR/mysql_backup_$DATE.tar.gz
