FROM viktorstrate/photoview:2.3.0

ADD ./docker_entrypoint.sh /app/docker_entrypoint.sh
RUN chmod a+x /app/docker_entrypoint.sh

ENTRYPOINT ["/app/docker_entrypoint.sh"]
