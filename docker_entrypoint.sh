#!/bin/sh

export PHOTOVIEW_MEDIA_CACHE="/root/persistance/cache"

export PHOTOVIEW_LISTEN_IP=$(ip -4 route list match 0/0 | awk '{print $3}')
export PHOTOVIEW_LISTEN_PORT=80

export PHOTOVIEW_DATABASE_DRIVER="sqlite"
export PHOTOVIEW_SQLITE_PATH="/root/persistance/photoview.db"

# start photoview executable
/app/photoview &
photoview_child=$!

wait -n $photoview_child
