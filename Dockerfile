FROM viktorstrate/photoview:2.3.0

# Install mariadb mysql database server
RUN apt-get update \
  && apt-get install -y mariadb-server \
  # Cleanup
  && apt-get autoremove -y \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

ADD ./db_setup.sql /app/db_setup.sql

ADD ./docker_entrypoint.sh /app/docker_entrypoint.sh
RUN chmod a+x /app/docker_entrypoint.sh

ENTRYPOINT ["/app/docker_entrypoint.sh"]
