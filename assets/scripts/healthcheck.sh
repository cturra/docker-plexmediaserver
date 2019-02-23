#!/bin/sh

CURL=$(which curl)

$CURL --connect-timeout 15 \
      --silent             \
      --show-error         \
      --fail               \
      "http://localhost:32400/identity" >/dev/null
