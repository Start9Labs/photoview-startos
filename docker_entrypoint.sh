#!/bin/bash

# _term() {
#   echo "caught SIGTERM signal!"
#   kill -TERM "$photoview_child" 2>/dev/null
# }

export PHOTOVIEW_MEDIA_CACHE="/media/cache"

export PHOTOVIEW_LISTEN_IP=0.0.0.0
export PHOTOVIEW_LISTEN_PORT=80

export PHOTOVIEW_DATABASE_DRIVER="sqlite"
export PHOTOVIEW_SQLITE_PATH="/media/photoview.db"

# start photoview executable
echo 'starting photoview server...'
/app/photoview &
photoview_child=$!

export USERS=$(sqlite3 $PHOTOVIEW_SQLITE_PATH 'select * from users;')

if [ -z "$USERS" ]; then
  echo Seeding initial user
  export PASS=$(cat /dev/urandom | base64 | head -c 16)
  mkdir -p /media/start9

  echo 'version: 2' > /media/start9/stats.yaml
  echo 'data:' >> /media/start9/stats.yaml
  echo '  Default Username:' >> /media/start9/stats.yaml
  echo '    type: string' >> /media/start9/stats.yaml
  echo '    value: admin' >> /media/start9/stats.yaml
  echo '    description: "Default useraname for Photoview. While it is not necessary, you may change it inside your Photoview application. That change, however will not be reflected here"' >> /media/start9/stats.yaml
  echo '    copyable: true' >> /media/start9/stats.yaml
  echo '    qr: false' >> /media/start9/stats.yaml
  echo '    masked: false' >> /media/start9/stats.yaml
  echo '  Default Password:' >> /media/start9/stats.yaml
  echo '    type: string' >> /media/start9/stats.yaml
  echo '    value: "'"$PASS"'"' >> /media/start9/stats.yaml
  echo '    description: This is your randomly-generated, default password. While it is not necessary, you may change it inside your Photoview application. That change, however, will not be reflected here.' >> /media/start9/stats.yaml
  echo '    copyable: true' >> /media/start9/stats.yaml
  echo '    masked: true' >> /media/start9/stats.yaml
  echo '    qr: false' >> /media/start9/stats.yaml

  echo INSERTING INITIAL USER
  PASS_HASH=$(htpasswd -bnBC 12 "" $PASS | tr -d ':\n' | sed 's/$2y/$2a/')
  PATH_MD5=$(echo -n /mnt/filebrowser | md5sum | head -c 32)

  USER_INSERT="insert into users (id, created_at, updated_at, username, password, admin) values (1, datetime('now'), datetime('now'), 'admin', '$PASS_HASH', true);"
  ALBUM_INSERT="insert into albums (id, created_at, updated_at, title, parent_album_id, path, path_hash) values (1, datetime('now'), datetime('now'), 'filebrowser', NULL, '/mnt/filebrowser', '$PATH_MD5');"
  JOIN_INSERT="insert into user_albums (album_id, user_id) values (1, 1);"
  INFO_UPDATE="update site_info set initial_setup = false;"

  test -f $PHOTOVIEW_SQLITE_PATH
  while [ $? -ne 0 ]; do
    echo "Waiting for database..."
  done

  sqlite3 $PHOTOVIEW_SQLITE_PATH "begin; $USER_INSERT $ALBUM_INSERT $JOIN_INSERT $INFO_UPDATE commit;"
  while [ $? -ne 0 ]; do
    sqlite3 $PHOTOVIEW_SQLITE_PATH "begin; $USER_INSERT $ALBUM_INSERT $JOIN_INSERT $INFO_UPDATE commit;"
  done
fi

wait -n $photoview_child
