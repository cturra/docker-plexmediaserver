#!/bin/bash

DOWNLOAD_DIR="/plex/downloads"

# ensure plex server version env variable is present
if [ "${PLEX_SERVER_VERSION}" == "" ]; then
  echo "[ERROR] No Plex server version defined."
  exit 1
fi

# check if /plex directory is present
if [ ! -d "${DOWNLOAD_DIR}" ]; then
  mkdir ${DOWNLOAD_DIR}
fi

# check if plex intsall file already exists on disk
# if not, download it
if [ ! -f "${DOWNLOAD_DIR}/plexmediaserver_${PLEX_SERVER_VERSION}.deb" ]; then
  # download plex media server
  wget -O ${DOWNLOAD_DIR}/plexmediaserver_${PLEX_SERVER_VERSION}.deb \
       -q https://downloads.plex.tv/plex-media-server/${PLEX_SERVER_VERSION}/plexmediaserver_${PLEX_SERVER_VERSION}_${PLEX_SERVER_ARCH}.deb
fi

# install latest plex media server
dpkg -i ${DOWNLOAD_DIR}/plexmediaserver_${PLEX_SERVER_VERSION}.deb

# update default config file
mv -f /tmp/default-plexmediaserver /etc/default/plexmediaserver

# start supervisor
/usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
