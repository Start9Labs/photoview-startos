#!/bin/bash

_term() {
  echo "caught SIGTERM signal!"
  kill -TERM "$photoview_child" 2>/dev/null
}

export PHOTOVIEW_MEDIA_CACHE="/root/persistance/cache"

export PHOTOVIEW_LISTEN_IP=0.0.0.0
export PHOTOVIEW_LISTEN_PORT=80

export PHOTOVIEW_DATABASE_DRIVER="sqlite"
export PHOTOVIEW_SQLITE_PATH="/root/persistance/photoview.db"

# start photoview executable
echo 'starting photoview server...'
/app/photoview &
photoview_child=$!

wait -n $photoview_child
