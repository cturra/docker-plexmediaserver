#!/bin/bash

# directory to store plex build downloads
DOWNLOAD_DIR="/plex/downloads"
# plex library
PLEX_LIBRARY="/plex/Library"
# supervisord logs
SUPERVISORD_LOGS="/plex/logs/supervisor"

# number of previous releases to keep in download directory
PLEX_NUM=2

CURL=$(which curl)
JQ=$(which jq)
DPKG=$(which dpkg)

plex_public () {
  PLEX_SERVER_VERSION=$($CURL -s https://plex.tv/downloads| grep ".deb"| grep -m 1 ${PLEX_SERVER_ARCH}| sed "s|.*plex-media-server/\(.*\)/plexmediaserver.*|\1|")
}

plex_plexpass () {
  # create POST payload
  AUTH="user%5Blogin%5D=${PLEXPASS_USER}&user%5Bpassword%5D=${PLEXPASS_PASS}"
  # auth against plex.tv and pull down X-Plex-Token
  CURL_OPTS="-s -H X-Plex-Client-Identifier:docker-plexmediaserver -H X-Plex-Product:docker-plexmediaserver -H X-Plex-Version:0.0.1"
  TOKEN=$($CURL ${CURL_OPTS} --data "${AUTH}" 'https://plex.tv/users/sign_in.json'| $JQ -r .user.authentication_token)

  if [ ${TOKEN} == "null" ] || [ -z ${TOKEN} ]; then
    echo "[INFO] Unable to authenticate, falling back to public release"
    plex_public
  else
    # grab downloads now
    PLEX_SERVER_VERSION=$($CURL ${CURL_OPTS} -H "X-Plex-Token:${TOKEN}" 'https://plex.tv/downloads?channel=plexpass'| grep ".deb"| grep -m 1 ${PLEX_SERVER_ARCH}| sed "s|.*plex-media-server/\(.*\)/plexmediaserver.*|\1|")
  fi
}

# check which plex server version to install
case "${PLEX_SERVER_VERSION}" in
  "public")
    plex_public
    ;;
  "plexpass")
    plex_plexpass
    ;;
  *)
    echo "[INFO] Using ${PLEX_SERVER_VERSION}"
    ;;
esac

# ensure plex server version env variable is present
if [ "${PLEX_SERVER_VERSION}" == "" ] || [ "${PLEX_SERVER_ARCH}" == "" ]; then
  echo "[ERROR] No Plex server version or architecture are defined."
  exit 1
fi

# check if /plex directory is present
if [ ! -d "${DOWNLOAD_DIR}" ]; then
  echo "[INFO] Creating ${DOWNLOAD_DIR}"
  mkdir ${DOWNLOAD_DIR}
fi

# check if plex install file already exists on disk
# if not, download it
if [ ! -f "${DOWNLOAD_DIR}/plexmediaserver_${PLEX_SERVER_VERSION}.deb" ]; then
  # download plex media server
  echo "[INFO] downloading plexmediaserver_${PLEX_SERVER_VERSION}"
  $CURL -s --retry 2 -o ${DOWNLOAD_DIR}/plexmediaserver_${PLEX_SERVER_VERSION}.deb \
        https://downloads.plex.tv/plex-media-server/${PLEX_SERVER_VERSION}/plexmediaserver_${PLEX_SERVER_VERSION}_${PLEX_SERVER_ARCH}.deb
  if [ $? -ne 0 ]; then
    echo "[ERROR] Unable to download https://downloads.plex.tv/plex-media-server/${PLEX_SERVER_VERSION}/plexmediaserver_${PLEX_SERVER_VERSION}_${PLEX_SERVER_ARCH}.deb"
    exit 1
  fi
fi

# check if plex already installed
$($DPKG -s plexmediaserver 2>/dev/null)
if [ $? -eq 0 ]; then
  # compare installed version to what we think is latest
  INSTALLED_PLEX=$($DPKG -s plexmediaserver| awk '/Version/ {print $2}')
  if [ "${INSTALLED_PLEX}" == "${PLEX_SERVER_VERSION}" ]; then
    echo "[INFO] Plex ${PLEX_SERVER_VERSION} already installed, skipping"
  else
    # install latest plex media server
    $DPKG -i ${DOWNLOAD_DIR}/plexmediaserver_${PLEX_SERVER_VERSION}.deb
  fi
else
  # plex not installed
  $DPKG -i ${DOWNLOAD_DIR}/plexmediaserver_${PLEX_SERVER_VERSION}.deb
fi

if [ $? -ne 0 ]; then
  echo "[ERROR] Unable to install ${DOWNLOAD_DIR}/plexmediaserver_${PLEX_SERVER_VERSION}.deb"
  echo "        try removing plexmediaserver_${PLEX_SERVER_VERSION}.deb before restarting"
  exit 1
fi

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
  echo "[INFO] Copying config to /etc/default/plexmediaserver"
  mv -f /tmp/default-plexmediaserver /etc/default/plexmediaserver
fi

# force update plex user to match NFS user if defined
if [[ (! -z ${PLEX_UID}) && (! -z ${PLEX_GID}) ]]; then
  echo "[INFO] Setting up PLEX UID:${PLEX_UID} and GID:${PLEX_GID}"
  groupmod -g ${PLEX_GID} plex
  usermod -u ${PLEX_UID} plex
fi

# preseed plex library and ensure permissions are setup properly
if [ ! -d ${PLEX_LIBRARY} ]; then
  echo "[INFO] Setting up PLEX Library at ${PLEX_LIBRARY}"
  mkdir -p -m 2775 ${PLEX_LIBRARY}
  chown -R plex:plex ${PLEX_LIBRARY}
else
  # ensure permissions are correct if we exist
  echo "[INFO] Ensuring plex library user permissions are correct"
  find ${PLEX_LIBRARY} ! -user plex -exec chown plex:plex {} \;
  chmod 2775 ${PLEX_LIBRARY}
fi

# ensure supervisor logfile is present
if [ ! -f ${SUPERVISORD_LOGS}/plex.log ]; then
  echo "[INFO] Setting up ${SUPERVISORD_LOGS}"
  mkdir -p ${SUPERVISORD_LOGS}
  touch ${SUPERVISORD_LOGS}/plex.log
fi

# start supervisor
/usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
