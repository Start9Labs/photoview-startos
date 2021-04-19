#!/bin/bash

export PASS=$(cat /dev/urandom | base64 | head -c 16)

yq e -n '.type = "string"' > /media/start9/stats.yaml
yq e -i ".value = \"$PASS\"" /media/start9/stats.yaml
yq e -i '.description = "Default password for Photoview, if you changed this in the Photoview web application, it will no longer work"' /media/start9/stats.yaml
yq e -i '.copyable = true' /media/start9/stats.yaml
yq e -i '.qr = false' /media/start9/stats.yaml
yq e -i '.masked = true' /media/start9/stats.yaml
yq e -i '{ "Password": . }' /media/start9/stats.yaml
yq e -i '{ "data": . }' /media/start9/stats.yaml
yq e -i '.version = 2' /media/start9/stats.yaml

export PASS_HASH=$(htpasswd -bnBC 12 "" $PASS | tr -d ':\n' | sed 's/$2y/$2a/')
export PHOTOVIEW_SQLITE_PATH="/media/photoview.db"
sqlite3 $PHOTOVIEW_SQLITE_PATH "update users set password = '$PASS_HASH' where id = 1;"