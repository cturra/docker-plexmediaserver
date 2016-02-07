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
  $DOCKER run --name=${CONTAINER_NAME} ${DOCKER_OPTS}          \
              --restart=always                                 \
              --net=host                                       \
              --env=PLEX_SERVER_VERSION=${PLEX_SERVER_VERSION} \
              --env=PLEX_SERVER_ARCH=${PLEX_SERVER_ARCH}       \
              --volume=${LOCAL_MOVIE_DIR}:/movies:ro           \
              --volume=${LOCAL_TV_DIR}:/tv:ro                  \
              --volume=${LOCAL_PLEX_DIR}:/plex:rw              \
              -d ${IMAGE_NAME}:latest > /dev/null
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
