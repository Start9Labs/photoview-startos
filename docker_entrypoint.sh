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

yq e -n '.type = "string"' > /media/start9/stats.yaml
yq e -i '.value = "/media/start9/public/filebrowser"' /media/start9/stats.yaml
yq e -i '.description = "The File Browser base directory to scan for media files."' /media/start9/stats.yaml
yq e -i '.copyable = true' /media/start9/stats.yaml
yq e -i '.qr = false' /media/start9/stats.yaml
yq e -i '.masked = false' /media/start9/stats.yaml
yq e -i '{ "Photo Path": . }' /media/start9/stats.yaml
yq e -i '{ "data": . }' /media/start9/stats.yaml
yq e -i '.version = 2' /media/start9/stats.yaml

# start photoview executable
echo 'starting photoview server...'
/app/photoview &
photoview_child=$!

wait -n $photoview_child
