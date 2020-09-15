#!/bin/bash

# plex.tv base download locations (url)
PLEX_DOWNLOAD_BASE_URL="https://plex.tv/pms/downloads/"
PUBLIC_DOWNLOAD_URL="${PLEX_DOWNLOAD_BASE_URL}/5.json"
PLEXPASS_DOWNLOAD_URL="${PLEX_DOWNLOAD_BASE_URL}/5.json?channel=plexpass"

# directory to store plex build downloads
INSTALLER_DIR="/plex/installers"

# plex library
PLEX_LIBRARY="/plex/Library"

# number of previous releases to keep in download directory
PLEX_NUM=2

# curl arguments
CURL_OPTS="-s -H X-Plex-Client-Identifier:docker-plexmediaserver -H X-Plex-Product:docker-plexmediaserver -H X-Plex-Version:0.0.1"

# binary packages
CURL=$(which curl)
JQ=$(which jq)
DPKG=$(which dpkg)


plex_public () {
  DISTRO="debian"
  BUILD="linux-x86_64"
  URL=$(get_plex_url ${DISTRO} ${BUILD} ${PUBLIC_DOWNLOAD_URL})
  download_plex ${URL}
}

plex_plexpass () {
  DISTRO="debian"
  BUILD="linux-x86_64"

  # create POST payload
  AUTH="user%5Blogin%5D=${PLEXPASS_USER}&user%5Bpassword%5D=${PLEXPASS_PASS}"
  # auth against plex.tv and pull down X-Plex-Token
  TOKEN=$($CURL ${CURL_OPTS} --data "${AUTH}" 'https://plex.tv/users/sign_in.json'| $JQ -r .user.authentication_token)

  if [ ${TOKEN} == "null" ] || [ -z ${TOKEN} ]; then
    echo "[INFO] Unable to authenticate, falling back to public release"
    plex_public
  else
    CURL_OPTS="${CURL_OPTS} -H X-Plex-Token:${TOKEN}"
    URL=$(get_plex_url ${DISTRO} ${BUILD} ${PLEXPASS_DOWNLOAD_URL})
    download_plex ${URL}
  fi
}

get_plex_url () {
  DISTRO=${1}
  BUILD=${2}
  DOWNLOAD_URL=${3}
  URL=$($CURL ${CURL_OPTS} "${DOWNLOAD_URL}"| ${JQ} -r --arg build ${BUILD} --arg distro "${DISTRO}" '.computer.Linux.releases[] | select(.build == $build and .distro == $distro) .url')
  echo ${URL}
}

download_plex () {
  URL=$1
  # check if /plex directory is present
  if [ ! -d "${INSTALLER_DIR}" ]; then
    echo "[INFO] Creating ${INSTALLER_DIR}"
    mkdir ${INSTALLER_DIR}
  fi

  # parse PLEX_SERVER_VERSION from URL
  PLEX_SERVER_VERSION=${URL%_*}
  PLEX_SERVER_VERSION=${PLEX_SERVER_VERSION#*_}

  # check if plex install file already exists on disk
  # if not, download it
  if [ ! -f "${INSTALLER_DIR}/plexmediaserver_${PLEX_SERVER_VERSION}.deb" ]; then
    # download plex media server
    echo "[INFO] Downloading plexmediaserver_${PLEX_SERVER_VERSION}"
    $CURL -s --retry 2 -o ${INSTALLER_DIR}/plexmediaserver_${PLEX_SERVER_VERSION}.deb ${URL}
    if [ $? -ne 0 ]; then
      echo "[ERROR] Unable to download ${URL}"
      exit 1
    fi
  fi
}

# update /proc/1/comm to fake out dbpkg preinst check by pretending
# to be the official pms container.
echo "s6-svscan" > /proc/1/comm

# check which plex server version to install
case "${PLEX_SERVER_VERSION}" in
  "plexpass")
    plex_plexpass
    ;;
  *)
    plex_public
    ;;
esac

# check if plex already installed
if [[ "$($DPKG --status plexmediaserver 2>/dev/null| grep Status\:)" == *"ok installed" ]]; then
  # compare installed version to what we think is latest
  INSTALLED_PLEX=$($DPKG -s plexmediaserver| awk '/Version/ {print $2}')
  if [ "${INSTALLED_PLEX}" == "${PLEX_SERVER_VERSION}" ]; then
    echo "[INFO] Plex ${PLEX_SERVER_VERSION} already installed, skipping"
  else
    # install latest plex media server
  echo "[INFO] Installing Plex ${PLEX_SERVER_VERSION}."
    $DPKG --install --force-confold ${INSTALLER_DIR}/plexmediaserver_${PLEX_SERVER_VERSION}.deb
  fi
else
  # plex not installed
  echo "[INFO] Installing Plex ${PLEX_SERVER_VERSION}."
  $DPKG --install --force-confold ${INSTALLER_DIR}/plexmediaserver_${PLEX_SERVER_VERSION}.deb
fi

if [ $? -ne 0 ]; then
  echo "[ERROR] Unable to install ${INSTALLER_DIR}/plexmediaserver_${PLEX_SERVER_VERSION}.deb"
  echo "        try removing plexmediaserver_${PLEX_SERVER_VERSION}.deb before restarting"
  exit 1
fi

# clean up old builds
i=0
for BUILD in $(find ${INSTALLER_DIR} -name plexmediaserver*.deb -print0| xargs -0 ls -t); do
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

# ensure plex user exists
if [ "$(id -u plex > /dev/null 2>&1; echo $?)" -eq "1" ]; then
  echo "[INFO] 'plex' user not found. Creating."
  useradd plex
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
# plex library directory exists, but permissions are incorrect
elif [ $(stat -c %a ${PLEX_LIBRARY}) != "2775" ]; then
  echo "[INFO] Updating plex library user permissions"
  chmod 2775 ${PLEX_LIBRARY}
  find ${PLEX_LIBRARY} ! -user plex -exec chown plex:plex {} \;
fi

# start supervisor
/usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
