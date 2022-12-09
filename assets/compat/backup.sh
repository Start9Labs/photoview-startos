#!/bin/bash

set -ea

case "$1" in
  backup-create)
    mkdir -p /mnt/backup/media
    compat duplicity create /mnt/backup/media /media

    mkdir -p /mnt/backup/database
    compat duplicity create /mnt/backup/database /var/lib/postgresql/14

    mkdir -p /mnt/backup/dbconfig
    compat duplicity create /mnt/backup/dbconfig /etc/postgresql/14
  ;;
  backup-restore)
    compat duplicity restore /mnt/backup/media /media
    compat duplicity restore /mnt/backup/database /var/lib/postgresql/14
    compat duplicity restore /mnt/backup/dbconfig /etc/postgresql/14
    ;;
  *)
esac

exit 0