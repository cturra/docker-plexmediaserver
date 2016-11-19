FROM ubuntu:16.04

ENV DEBIAN_FRONTEND noninteractive

# install/config supervisord and grab curl and jq
# so we can download plex
RUN apt-get -qq update             \
 && apt-get -yf install supervisor \
                        curl       \
                        jq         \
 && rm -rf /var/lib/apt/lists/*

# copy config files into container
COPY assets/configs/supervisor/plex.conf         /etc/supervisor/conf.d/
COPY assets/configs/plex/default-plexmediaserver /tmp/

# install startup script
COPY assets/scripts/startup.sh /opt/startup.sh

# kick off startup script
ENTRYPOINT [ "/opt/startup.sh" ]
