#!/bin/bash

_term() {
  echo "caught SIGTERM signal!"
  kill -TERM "$photoview_child" 2>/dev/null
}

export PHOTOVIEW_MEDIA_CACHE="/media/cache"

export PHOTOVIEW_LISTEN_IP=0.0.0.0
export PHOTOVIEW_LISTEN_PORT=80

export PHOTOVIEW_DATABASE_DRIVER="sqlite"
export PHOTOVIEW_SQLITE_PATH="/media/photoview.db"

echo start9/public > .backupignore
echo start9/shared >> .backupignore

# start photoview executable
echo 'starting photoview server...'
/app/photoview &
photoview_child=$!

export USERS=$(sqlite3 $PHOTOVIEW_SQLITE_PATH 'select * from users;')

if [ -z $USERS ]; then
  echo Seeding initial user
  export PASS=$(cat /dev/urandom | base64 | head -c 16)

  yq e -n '.type = "string"' > /media/start9/stats.yaml
  yq e -i ".value = \"$PASS\"" /media/start9/stats.yaml
  yq e -i '.description = "Default password for Photoview, if you changed this in the Photoview web application, it will no longer work"' /media/start9/stats.yaml
  yq e -i '.copyable = true' /media/start9/stats.yaml
  yq e -i '.qr = false' /media/start9/stats.yaml
  yq e -i '.masked = true' /media/start9/stats.yaml
  yq e -i '{ "Password": . }' /media/start9/stats.yaml
  yq e -i '.Username.type = "string"' /media/start9/stats.yaml
  yq e -i '.Username.value = "admin"' /media/start9/stats.yaml
  yq e -i '.Username.description = "Default useraname for Photoview, if you changed this in teh Photoview web application, it will no longer work"' /media/start9/stats.yaml
  yq e -i '.Username.copyable = true' /media/start9/stats.yaml
  yq e -i '.Username.qr = false' /media/start9/stats.yaml
  yq e -i '.Username.masked = false' /media/start9/stats.yaml
  yq e -i '{ "data": . }' /media/start9/stats.yaml
  yq e -i '.version = 2' /media/start9/stats.yaml

  echo INSERTING INITIAL USER
  export PASS_HASH=$(htpasswd -bnBC 12 "" $PASS | tr -d ':\n' | sed 's/$2y/$2a/')
  sqlite3 $PHOTOVIEW_SQLITE_PATH "insert into users (id, created_at, updated_at, username, password, admin) values (1, datetime('now'), datetime('now'), 'admin', '$PASS_HASH', true);"
  while [ $? -ne 0 ]; do
    sqlite3 $PHOTOVIEW_SQLITE_PATH "insert into users (id, created_at, updated_at, username, password, admin) values (1, datetime('now'), datetime('now'), 'admin', '$PASS_HASH', true);"
  done

  echo INSERTING INITIAL ALBUM
  export PATH_MD5=$(echo -n /media/start9/public/filebrowser | md5sum | head -c 32)
  sqlite3 $PHOTOVIEW_SQLITE_PATH "insert into albums (id, created_at, updated_at, title, parent_album_id, path, path_hash) values (1, datetime('now'), datetime('now'), 'filebrowser', NULL, '/media/start9/public/filebrowser', '$PATH_MD5');"
  while [ $? -ne 0 ]; do
    sqlite3 $PHOTOVIEW_SQLITE_PATH "insert into albums (id, created_at, updated_at, title, parent_album_id, path, path_hash) values (1, datetime('now'), datetime('now'), 'filebrowser', NULL, '/media/start9/public/filebrowser', '$PATH_MD5');"
  done

  echo INSERTING USER ALBUM JOIN
  sqlite3 $PHOTOVIEW_SQLITE_PATH "insert into user_albums (album_id, user_id) values (1, 1);"
  while [ $? -ne 0 ]; do
    sqlite3 $PHOTOVIEW_SQLITE_PATH "insert into user_albums (album_id, user_id) values (1, 1);"
  done

  echo SETTING SITE INFO
  sqlite3 $PHOTOVIEW_SQLITE_PATH "update site_info set initial_setup = false;"
  while [ $? -ne 0 ]; do
    sqlite3 $PHOTOVIEW_SQLITE_PATH "update site_info set initial_setup = false;"
  done
fi

wait -n $photoview_child
