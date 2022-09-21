#!/bin/sh
sqlite3 /media/photoview.db "update albums set path = replace(path, '/media/start9/public/filebrowser', '/mnt/filebrowser'), path_hash = NULL;"
sqlite3 /media/photoview.db "update media set path = replace(path, '/media/start9/public/filebrowser', '/mnt/filebrowser');"
sqlite3 /media/photoview.db "update site_info set initial_setup = false, periodic_scan_interval = 300;"
echo '{"configured":false}'