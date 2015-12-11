#!/bin/bash

set -e

mkdir -p page
git clone -b gh-pages https://${GITHUB_TOKEN}@github.com/thriqon/mulled.git page >/dev/null 2>&1

function jsonForImage {
  IMAGE=$1
  REPO=thriqon/mulled:$IMAGE
  PACKAGER=$2

  echo "{\"image\": \"$IMAGE\", \"date\": \"$(date -Iseconds)\", "
  echo "\"info\": $(cat info/info.json | jq .[0]), "
  if [[ $TRAVIS_PULL_REQUEST == "false" ]]; then
    echo -n "\"published\": true, "
  fi
  echo -n "\"size\": \"$(docker inspect -f "{{.VirtualSize}}" $REPO | numfmt --to=iec-i --suffix=B)\", "
  echo -n "\"checksum\": \"$(docker save $REPO | sha256sum - | cut -d' ' -f 1)\", "
  echo -n "\"buildurl\": \"https://travis-ci.org/thriqon/mulled/builds/$TRAVIS_BUILD_ID\", "
  echo -n "\"packager\": \"$PACKAGER\"}"
}

function buildPackage {
  PACKAGER=$1
  PACKAGE=$2
  BINARY=$2
  ADDITIONAL_PACKAGES=$3

  PACKAGE=$PACKAGE BINARY=$BINARY ADDITIONAL_PACKAGES=$ADDITIONAL_PACKAGES ./involucro -f ${PACKAGER}.lua build package

  POST_FILENAME=page/_posts/2015-01-01-$PACKAGE.html
  DATA_FILENAME=page/_data/$PACKAGE.json
  jsonForImage $PACKAGE $PACKAGER | jq . > $DATA_FILENAME
  (
    echo "---"
    echo "layout: post"
    echo "image: $PACKAGE"
    echo "---"
  ) > $POST_FILENAME

  if [[ $TRAVIS_PULL_REQUEST == "false" ]]; then
    docker push thriqon/mulled:$PACKAGE
  fi
  
  PACKAGE=$PACKAGE BINARY=$BINARY ADDITIONAL_PACKAGES=$ADDITIONAL_PACKAGES ./involucro -f ${PACKAGER}.lua clean
}

(while read line; do
  if [[ $line == \#* ]]; then continue; fi
  IFS=$'\t' read -ra FIELDS <<< "$line"

  buildPackage ${FIELDS[0]} ${FIELDS[1]} ${FIELDS[2]} ${FIELDS[3]}
done) < packages.tsv

git config --global user.name "Travis BuildBot"
git config --global user.email "travis@mulled.jonasw.de"

(cd page ; git add . ; git commit -m "results for $TRAVIS_BUILD_NR" -m "" -m "commit range $TRAVIS_COMMIT_RANGE" -m "travis build https://travis-ci.org/$TRAVIS_REPO_SLUG/builds/$TRAVIS_BUILD_ID" ; git push -q origin gh-pages > /dev/null 2>&1)

