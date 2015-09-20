FROM ubuntu:14.04

MAINTAINER chris turra <cturra@gmail.com>

ENV DEBIAN_FRONTEND     noninteractive
ENV PLEX_ARCH           amd64
ENV PLEX_SERVER_VERSION 0.9.12.12.1459-49fe448

# install/config supervisord
RUN apt-get -qq update && \
    apt-get -yf install supervisor \
                        wget

# install/config plex standalone server
RUN wget -O /tmp/plexmediaserver.deb -q https://downloads.plex.tv/plex-media-server/${PLEX_SERVER_VERSION}/plexmediaserver_${PLEX_SERVER_VERSION}_${PLEX_ARCH}.deb && \
    dpkg -i /tmp/plexmediaserver.deb && \
    rm -f /tmp/plexmediaserver.deb

ADD conf/supervisord.conf /etc/supervisor/conf.d/plex.conf
ADD conf/default-plexmediaserver /etc/default/plexmediaserver

RUN mkdir /movies /tv /plex

EXPOSE 32400

# kick off supervisord+plex
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/plex.conf"]
