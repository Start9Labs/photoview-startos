#!/bin/sh
PATH_MD5=$(echo -n /mnt/filebrowser | md5sum | head -c 32)
sqlite3 /media/photoview.db "update albums set path = '/mnt/filebrowser', path_hash = '$PATH_MD5' where id = 1;"