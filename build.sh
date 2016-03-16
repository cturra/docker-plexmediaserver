#!/bin/bash

# grab global variables
source vars

# generate a build tag based on plex server version
if [[ "${PLEX_SERVER_VERSION}" == "public" || "${PLEX_SERVER_VERSION}" == "plexpass" ]] ; then
  BUILD_TAG=${PLEX_SERVER_VERSION}
else
  BUILD_TAG= $(echo ${PLEX_SERVER_VERSION}| awk -F'.' '{print $1"."$2"."$3"."$4}')
fi

DOCKER=$(which docker)

# build image and tag with build tag (plex version number)
$DOCKER build -t ${IMAGE_NAME}:${BUILD_TAG} .

# add latest tag
$DOCKER tag ${IMAGE_NAME}:${BUILD_TAG} ${IMAGE_NAME}:latest
