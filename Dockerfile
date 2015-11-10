FROM ubuntu:14.04

MAINTAINER chris turra <cturra@gmail.com>

ENV DEBIAN_FRONTEND     noninteractive
ENV PLEX_ARCH           amd64
ENV PLEX_SERVER_VERSION 0.9.14.0.1539-61cdd0f

# install/config supervisord and grab wget
# so we can download plex
RUN apt-get -qq update && \
    apt-get -yf install supervisor \
                        wget && \
    rm -rf /var/lib/apt/lists/*

COPY conf/supervisord.conf /etc/supervisor/conf.d/plex.conf

# download/install/config plex standalone server
RUN wget -O /tmp/plexmediaserver.deb \
         -q https://downloads.plex.tv/plex-media-server/${PLEX_SERVER_VERSION}/plexmediaserver_${PLEX_SERVER_VERSION}_${PLEX_ARCH}.deb && \
    dpkg -i /tmp/plexmediaserver.deb && \
    rm -f /tmp/plexmediaserver.deb

COPY conf/default-plexmediaserver /etc/default/plexmediaserver

EXPOSE 32400/tcp

# kick off supervisord+plex
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/plex.conf"]
