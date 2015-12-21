#!/bin/bash

IMAGE_NAME="cturra/plex"
BUILD_TAG=$(grep "ENV PLEX_SERVER_VERSION" Dockerfile| awk '{print $3}'| awk -F"." '{print $1"."$2"."$3"."$4}')
DOCKER=$(which docker)

# build image and tag with build tag (plex version number)
$DOCKER build -t ${IMAGE_NAME}:${BUILD_TAG} .

# add latest tag
$DOCKER tag --force ${IMAGE_NAME}:${BUILD_TAG} ${IMAGE_NAME}:latest
