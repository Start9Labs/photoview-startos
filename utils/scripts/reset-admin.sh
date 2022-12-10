#!/bin/bash

# ensure start9 directory exists if action is run before first run of service
mkdir -p /media/start9
export PASS=$(cat /dev/urandom | base64 | head -c 16)
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

export PASS_HASH=$(htpasswd -bnBC 12 "" $PASS | tr -d ':\n' | sed 's/$2y/$2a/')

service postgresql start &>/dev/null
USERS=$(su - postgres -c 'psql -d '$POSTGRES_DB' -c "select * from users"')
if [ -z $USERS ]; then
  PASS_HASH=$(htpasswd -bnBC 12 "" $PASS | tr -d ':\n' | sed 's/$2y/$2a/')
  PATH_MD5=$(echo -n /mnt/filebrowser | md5sum | head -c 32)
  USER_INSERT="INSERT INTO users (id, created_at, updated_at, username, password, admin) VALUES (21, current_timestamp, current_timestamp, 'admin', '$PASS_HASH', true);"
  ALBUM_INSERT="INSERT INTO albums (id, created_at, updated_at, title, parent_album_id, path, path_hash) VALUES (21, current_timestamp, current_timestamp, 'filebrowser', NULL, '/mnt/filebrowser', '$PATH_MD5');"
  JOIN_INSERT="INSERT INTO user_albums (album_id, user_id) VALUES (21, 21);"
  INFO_UPDATE="update site_info set initial_setup = false;"
  echo "begin; $USER_INSERT $ALBUM_INSERT $JOIN_INSERT $INFO_UPDATE commit;" | su - postgres -c "psql -d '$POSTGRES_DB'" &>/dev/null
fi
SET_PW="UPDATE users SET password = '$PASS_HASH', username = 'admin' WHERE id = 21;"
echo $SET_PW | su - postgres -c "psql -d '$POSTGRES_DB'" &>/dev/null
service postgresql stop &>/dev/null
action_result="    {
    \"version\": \"0\",
    \"message\": \"Here is your new password. This will also be reflected in the Properties page for this service.\",
    \"value\": \"$PASS\",
    \"copyable\": true,
    \"qr\": false
}"
echo $action_result
exit 0