#!/bin/bash

# directory to store plex build downloads
DOWNLOAD_DIR="/plex/downloads"
# plex library
PLEX_LIBRARY="/plex/Library"
# supervisord logs
SUPERVISORD_LOGS="/plex/logs/supervisor"

# number of previous releases to keep in download directory
PLEX_NUM=2

# ensure plex server version env variable is present
if [ "${PLEX_SERVER_VERSION}" == "" ] || [ "${PLEX_SERVER_ARCH}" == "" ]; then
  echo "[ERROR] No Plex server version or architecture are defined."
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
  echo "downloading plexmediaserver_${PLEX_SERVER_VERSION}"
  wget -O ${DOWNLOAD_DIR}/plexmediaserver_${PLEX_SERVER_VERSION}.deb \
       -q https://downloads.plex.tv/plex-media-server/${PLEX_SERVER_VERSION}/plexmediaserver_${PLEX_SERVER_VERSION}_${PLEX_SERVER_ARCH}.deb
fi

# install latest plex media server
dpkg -i ${DOWNLOAD_DIR}/plexmediaserver_${PLEX_SERVER_VERSION}.deb

# clean up old builds
i=0
for BUILD in $(find ${DOWNLOAD_DIR} -name plexmediaserver*.deb -print0| xargs -0 ls -t); do
  # is counter greater than number of builds to keep?
  if [ $i -gt ${PLEX_NUM} ]; then
    rm -f $BUILD
  fi
  # increase counter
  let i+=1
done

# update default config file
if [ -f /tmp/default-plexmediaserver ]; then
  echo "copying config to /etc/default/plexmediaserver"
  mv -f /tmp/default-plexmediaserver /etc/default/plexmediaserver
fi

# force update plex user to match NFS user if defined
if [[ (! -z ${PLEX_UID}) && (! -z ${PLEX_GID}) ]]; then
  echo "setting up PLEX UID:${PLEX_UID} and GID:${PLEX_GID}"
  groupmod -g ${PLEX_GID} plex
  usermod -u ${PLEX_UID} plex
fi

# preseed plex library and ensure permissions are setup properly
if [ ! -d ${PLEX_LIBRARY} ]; then
  echo "setting up PLEX Library"
  mkdir -p -m 2775 ${PLEX_LIBRARY}
  chown -R plex:plex ${PLEX_LIBRARY}
else
  # ensure permissions are correct if we exist
  chown -R plex:plex ${PLEX_LIBRARY}
  chmod 2775 ${PLEX_LIBRARY}
fi

# ensure supervisor logfile is present
if [ ! -f ${SUPERVISORD_LOGS}/plex.log ]; then
  echo "setting up ${SUPERVISORD_LOGS}"
  mkdir -p ${SUPERVISORD_LOGS}
  touch ${SUPERVISORD_LOGS}/plex.log
fi

# start supervisor
/usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
