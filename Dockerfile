FROM ubuntu:16.04

ENV DEBIAN_FRONTEND noninteractive

# install/config supervisord and grab curl and jq
# so we can download plex
RUN apt-get -q update             \
 && apt-get -y install supervisor \
                        curl      \
                        jq        \
 && rm -rf /var/lib/apt/lists/*

# copy config files into container
COPY assets/configs/supervisor/plex.conf         /etc/supervisor/conf.d/
COPY assets/configs/plex/default-plexmediaserver /tmp/

# install startup & healthcheck scripts
COPY assets/scripts/* /opt/

# let docker know how to test container health
HEALTHCHECK --interval=5s --timeout=2s --retries=20 CMD /opt/healthcheck.sh || exit 1

# kick off startup script
ENTRYPOINT [ "/opt/startup.sh" ]
