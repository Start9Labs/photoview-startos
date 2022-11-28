FROM viktorstrate/photoview:2.3.13

# arm64 or amd64
ARG PLATFORM
ARG ARCH
ENV PHOTOVIEW_DATABASE_DRIVER postgres
ENV POSTGRES_DB photoview
ENV PHOTOVIEW_POSTGRES_DB photoview 
ENV POSTGRES_USER photoview
ENV POSTGRES_PASSWORD=
ENV POSTGRES_HOST localhost
ENV PHOTOVIEW_LISTEN_IP=0.0.0.0
ENV PHOTOVIEW_LISTEN_PORT=80
ENV PHOTOVIEW_MEDIA_CACHE "/media/cache"
ENV PHOTOVIEW_SQLITE_PATH "/media/photoview.db"
ENV POSTGRES_DATADIR "/var/lib/postgresql/14"
ENV POSTGRES_CONFIG="/etc/postgresql/14"
VOLUME $POSTGRES_DATADIR
VOLUME $POSTGRES_CONFIG

# Install mariadb mysql database server
RUN apt-get update \
  && apt-get install -y mariadb-server wget sqlite3 apache2-utils curl sudo gnupg2
RUN apt-get install postgresql -y
  # Cleanup
RUN apt-get autoremove -y \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN wget https://github.com/mikefarah/yq/releases/download/v4.6.3/yq_linux_${PLATFORM}.tar.gz -O - |\
  tar xz && mv yq_linux_${PLATFORM} /usr/bin/yq

ADD ./example.env /app/.env
ADD ./reset-admin.sh /usr/local/bin/reset-admin.sh
ADD ./docker_entrypoint.sh /usr/local/bin/docker_entrypoint.sh
ADD ./migration-from-lt-2-3-9.sh /usr/local/bin/migration-from-lt-2-3-9.sh
RUN chmod a+x /usr/local/bin/*.sh
