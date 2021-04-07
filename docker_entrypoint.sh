#!/bin/bash

_term() {
  echo "caught SIGTERM signal!"
  kill -TERM "$mariadb_child" 2>/dev/null
  kill -TERM "$photoview_child" 2>/dev/null
}

export PHOTOVIEW_MEDIA_CACHE="/root/persistance/cache"

export PHOTOVIEW_LISTEN_IP=0.0.0.0
export PHOTOVIEW_LISTEN_PORT=80

export PHOTOVIEW_DATABASE_DRIVER="mysql"
export PHOTOVIEW_MYSQL_URL="photoview:photosecret@tcp(localhost)/photoview"

# setup database
echo 'starting mariadb server...'
mysqld_safe &
mariadb_child=$!

while ! mysql -e '' 2> /dev/null; do
  echo 'waiting for mariadb to start...'
  sh -c "sleep 2"
done

if ! mysqlshow photoview > /dev/null 2>&1; then
  echo 'configuring initial database...'
  mysql -e "CREATE USER 'photoview'@'localhost' IDENTIFIED BY 'photosecret';
CREATE DATABASE photoview;
GRANT ALL PRIVILEGES ON photoview.* TO 'photoview'@'localhost';
FLUSH PRIVILEGES;"
fi

# start photoview executable
echo 'starting photoview server...'
/app/photoview &
photoview_child=$!

wait -n $mariadb_child $photoview_child
