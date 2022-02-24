FROM viktorstrate/photoview:2.3.9

# Install mariadb mysql database server
RUN apt-get update
RUN apt-get install -y mariadb-server wget sqlite3 apache2-utils curl
# Cleanup
RUN apt-get autoremove -y
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*

RUN wget https://github.com/mikefarah/yq/releases/download/v4.6.3/yq_linux_arm.tar.gz -O - |\
  tar xz && mv yq_linux_arm /usr/bin/yq

ADD ./reset-admin.sh /usr/local/bin/reset-admin.sh
RUN chmod a+x /usr/local/bin/reset-admin.sh
ADD ./docker_entrypoint.sh /app/docker_entrypoint.sh
RUN chmod a+x /app/docker_entrypoint.sh
COPY ./health-check.sh /usr/local/bin/health-check.sh
COPY ./migration-from-lt-2-3-9.sh /usr/local/bin/migration-from-lt-2-3-9.sh
RUN chmod a+x /usr/local/bin/health-check.sh

ENTRYPOINT ["/app/docker_entrypoint.sh"]
