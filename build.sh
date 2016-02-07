#!/bin/bash

# grab global variables
source vars

# generate a build tag based on plex server version
BUILD_TAG=$(echo ${PLEX_SERVER_VERSION}| awk -F'.' '{print $1"."$2"."$3"."$4}')

DOCKER=$(which docker)

# build image and tag with build tag (plex version number)
$DOCKER build -t ${IMAGE_NAME}:${BUILD_TAG} .

# add latest tag
$DOCKER tag ${IMAGE_NAME}:${BUILD_TAG} ${IMAGE_NAME}:latest
