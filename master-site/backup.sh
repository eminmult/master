#!/bin/bash
BACKUP_DIR="/root/master-site/backups"
DATE=$(date +%Y%m%d_%H%M)
docker exec master-db pg_dump -U master_user master_db | gzip > "$BACKUP_DIR/master_db_$DATE.sql.gz"
# Keep only last 20 backups
ls -t "$BACKUP_DIR"/master_db_*.sql.gz | tail -n +21 | xargs -r rm
echo "Backup done: master_db_$DATE.sql.gz"
