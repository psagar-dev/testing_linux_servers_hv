#!/bin/bash

# Variables
BACKUP_DIR="/backups"
DATE=$(date +%Y-%m-%d)
BACKUP_FILE="$BACKUP_DIR/apache_backup_$DATE.tar.gz"
LOG_FILE="$BACKUP_DIR/apache_backup_$DATE.log"

# Create backup directory if not exists
mkdir -p "$BACKUP_DIR" || {
    echo "Error: Failed to create backup directory." | tee -a "$LOG_FILE"
    exit 1
}

# Verify if the source directories exist
if [ ! -d "/etc/apache2" ] || [ ! -d "/var/www/html" ]; then
    echo "Error: One or more directories do not exist. Backup aborted." | tee -a "$LOG_FILE"
    exit 1
fi

# Create backup
echo "Creating Apache backup..." | tee -a "$LOG_FILE"
tar --absolute-names -czf "$BACKUP_FILE" /etc/apache2 /var/www/html || {
    echo "Error: Backup creation failed." | tee -a "$LOG_FILE"
    exit 1
}

# Verify backup integrity by listing contents
echo "Verifying backup integrity for $BACKUP_FILE" | tee -a "$LOG_FILE"
tar -tzf "$BACKUP_FILE" >> "$LOG_FILE" 2>&1 || {
    echo "Error: Backup verification failed." | tee -a "$LOG_FILE"
    exit 1
}

# Confirmation message
echo "Apache backup completed on $DATE and verified." | tee -a "$LOG_FILE"