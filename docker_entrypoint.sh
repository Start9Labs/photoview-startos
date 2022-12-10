#!/bin/bash

set -e

_term() {
  echo "caught SIGTERM signal!"
  kill -TERM "$photoview_child" 2>/dev/null
}

if test -f /etc/postgresql/14/photoview/postgresql.conf
then
  # restart
  echo "postgresql already initialized"
  echo "starting postgresql..."
  service postgresql start
else
  # fresh install
  echo 'setting up postgresql...'
  # set permissions for postgres folders
  chown -R postgres:postgres $POSTGRES_DATADIR
  chown -R postgres:postgres $POSTGRES_CONFIG
  chmod -R 700 $POSTGRES_DATADIR
  chmod -R 700 $POSTGRES_CONFIG
  mkdir -p /media/start9
  su - postgres -c "pg_createcluster 14 photoview"
  echo "starting postgresql..."
  service postgresql start
fi


echo 'checking for existing admin user...'
export USERS=$(sqlite3 $PHOTOVIEW_SQLITE_PATH 'select * from users;') 
export NEW_USERS=$(su - postgres -c 'psql -d '$POSTGRES_DB' -c "select * from users"')
sleep 1

if [ -f /media/start9/config.yaml ] && ! [ -z "$NEW_USERS" ]; then
  echo 'loading existing admin credentials...'
  export POSTGRES_PASSWORD=$(yq e '.password' /media/start9/config.yaml)
fi

if ! [ -z "$USERS" ] && [ -z "$NEW_USERS" ]; then
  echo 'existing user from previous version exists'
  export POSTGRES_PASSWORD=$(cat /dev/urandom | tr -dc '[:alnum:]' | head -c 16)
fi

if [ -z "$USERS" ] && [ -z "$NEW_USERS" ]; then 
  echo 'No admin users found.'
  echo 'Seeding initial user...'
  export POSTGRES_PASSWORD=$(cat /dev/urandom | tr -dc '[:alnum:]' | head -c 16)
fi

if [ -z "$NEW_USERS" ]; then
  rm -f /media/start9/config.yaml && touch /media/start9/config.yaml 
  echo "password: $POSTGRES_PASSWORD" > /media/start9/config.yaml
  echo 'Configuring properties page...'
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
  echo '    value: "'"$POSTGRES_PASSWORD"'"' >> /media/start9/stats.yaml
  echo '    description: This is your randomly-generated, default password. While it is not necessary, you may change it inside your Photoview application. That change, however, will not be reflected here.' >> /media/start9/stats.yaml
  echo '    copyable: true' >> /media/start9/stats.yaml
  echo '    masked: true' >> /media/start9/stats.yaml
  echo '    qr: false' >> /media/start9/stats.yaml
  echo 'Properties page ready.'

  if ! test -d /mnt/filebrowser; then
    echo "Filebrowser mountpoint does not exist. Please make sure you have Filebrowser running."
    exit 0
  fi

  echo 'applying database permissions...'
  su - postgres -c 'psql -c "UPDATE pg_database SET datistemplate = FALSE WHERE datname = '"'"template1"'"';"'
  su - postgres -c 'psql -c "DROP DATABASE template1;"'
  su - postgres -c 'psql -c "CREATE DATABASE template1 WITH TEMPLATE = template0 ENCODING = '"'"UTF8"'"';"'
  su - postgres -c 'psql -c "UPDATE pg_database SET datistemplate = TRUE WHERE datname = '"'"template1"'"';"'
  su - postgres -c "psql -d template1 -c 'VACUUM FREEZE;'"
  su - postgres -c "createuser $POSTGRES_USER"
  su - postgres -c "createdb $POSTGRES_DB"
  su - postgres -c 'psql -c "ALTER USER '$POSTGRES_USER' WITH ENCRYPTED PASSWORD '"'"$POSTGRES_PASSWORD"'"';"'
  su - postgres -c 'psql -c "grant all privileges on database '$POSTGRES_DB' to '$POSTGRES_USER';"'
  su - postgres -c 'echo "localhost:5432:'$POSTGRES_USER':'$POSTGRES_PASSWORD'" >> .pgpass'
  su - postgres -c "chmod -R 0600 .pgpass"
  chmod -R 0600 /var/lib/postgresql/.pgpass
  echo 'database permissions setup complete.'
fi

# start photoview executable
echo 'starting photoview server...'
sed -i "s/_photoview_password_/"$POSTGRES_PASSWORD"/" /app/.env 
/app/photoview &
photoview_child=$!

if [ -z "$NEW_USERS" ]; then 
  sleep 20
  echo "Inserting admin user into database..."
  PASS_HASH=$(htpasswd -bnBC 12 "" $POSTGRES_PASSWORD | tr -d ':\n' | sed 's/$2y/$2a/')
  PATH_MD5=$(echo -n /mnt/filebrowser | md5sum | head -c 32)
  USER_INSERT="insert into users (id, created_at, updated_at, username, password, admin) values (21, current_timestamp, current_timestamp, 'admin', '$PASS_HASH', true);"
  ALBUM_INSERT="insert into albums (id, created_at, updated_at, title, parent_album_id, path, path_hash) values (21, current_timestamp, current_timestamp, 'filebrowser', NULL, '/mnt/filebrowser', '$PATH_MD5');"
  JOIN_INSERT="insert into user_albums (album_id, user_id) values (21, 21);"
  INFO_UPDATE="update site_info set initial_setup = false;"
  echo "begin; $USER_INSERT $ALBUM_INSERT $JOIN_INSERT $INFO_UPDATE commit;"
  printf "begin; $USER_INSERT $ALBUM_INSERT $JOIN_INSERT $INFO_UPDATE commit;" | su - postgres -c "psql -d photoview"
  echo 'Photoview setup complete.'
fi

trap _term SIGTERM

wait -n $photoview_child
