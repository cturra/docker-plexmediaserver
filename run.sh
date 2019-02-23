#!/bin/bash

# grab global variables
source vars

DOCKER=$(which docker)

# function to check if container is running
function check_container() {
  $DOCKER ps --filter "name=${CONTAINER_NAME}" --format "{{.ID}}"
}

# function to start new docker container
function start_container() {
  # if defining plex uid and gid, pass it to docker
  # otherwise, nothing to see here
  USER_OPTS=""
  if [[ (! -z ${PLEX_UID}) && (! -z ${PLEX_GID}) ]]; then
    USER_OPTS="--env=PLEX_UID=${PLEX_UID} --env=PLEX_GID=${PLEX_GID}"
  fi

  PLEXPASS_OPT=""
  if [[ ${PLEX_SERVER_VERSION} == "plexpass" && (( -z ${PLEXPASS_USER}) || ( -z ${PLEXPASS_PASS} )) ]] ; then
    echo "[ERROR] Plex Pass release channel defined but missing PLEXPASS_USER or PLEXPASS_PASS"
    exit 1
  fi
  if [[ (! -z ${PLEXPASS_USER}) && (! -z ${PLEXPASS_PASS}) ]]; then
    PLEXPASS_OPTS="--env=PLEXPASS_USER=${PLEXPASS_USER} --env=PLEXPASS_PASS=${PLEXPASS_PASS}"
  fi

  $DOCKER run ${DOCKER_OPTS}                                   \
              --name=${CONTAINER_NAME}                         \
              --hostname=${CONTAINER_HOST_NAME}                \
              --detach=true                                    \
              --restart=on-failure:2                           \
              --publish=3005:3005/tcp                          \
              --publish=8324:8324/tcp                          \
              --publish=32400:32400/tcp                        \
              --publish=32469:32469/tcp                        \
              --publish=1900:1900/udp                          \
              --publish=32410:32410/udp                        \
              --publish=32412:32412/udp                        \
              --publish=32413:32413/udp                        \
              --publish=32414:32414/udp                        \
              --env=PLEX_SERVER_VERSION=${PLEX_SERVER_VERSION} \
              --volume=${LOCAL_MEDIA_DIR}:/media:ro            \
              --volume=${LOCAL_DATA_DIR}:/plex:rw              \
              ${USER_OPTS}                                     \
              ${PLEXPASS_OPTS}                                 \
              ${IMAGE_NAME}:latest > /dev/null
}

# check if docker container with same name is already running.
if [ "$(check_container)" != "" ]; then
  # container found...
  # 1) rename existing container
  $DOCKER rename ${CONTAINER_NAME} "${CONTAINER_NAME}_orig" > /dev/null 2>&1

  # 2) stop exiting container
  $DOCKER stop "${CONTAINER_NAME}_orig" > /dev/null 2>&1

  # 3) start new container
  start_container

  # 4) remover existing container
  if [ "$(check_container)" != "" ]; then
    $DOCKER rm "${CONTAINER_NAME}_orig" > /dev/null 2>&1
  fi

  # finally, lets clean up old docker images
  $DOCKER rmi $($DOCKER images -q ${IMAGE_NAME}) > /dev/null 2>&1

# no docker container found. start a new one.
else
  start_container
fi
