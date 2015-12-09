#!/bin/bash

set -e

(while read line; do
  if [[ $line == \#* ]]; then continue; fi

  IFS=$'\t' read -ra FIELDS <<< "$line"
  PACKAGER=${FIELDS[0]}
  PACKAGE=${FIELDS[1]} BINARY=${FIELDS[2]} ./involucro -f ${PACKAGER}.lua build package clean

  if [[ $TRAVIS_PULL_REQUEST == "false" ]]; then
    docker push thriqon/mulled:${FIELDS[1]}
  fi
done) < packages.tsv

