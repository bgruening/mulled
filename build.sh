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
  echo -n "\"published\": true, "
  echo -n "\"size\": \"$(docker inspect -f "{{.VirtualSize}}" $REPO | numfmt --to=iec-i --suffix=B)\", "
  echo -n "\"checksum\": \"$(cat digest.txt)\", "
  echo -n "\"buildurl\": \"https://travis-ci.org/thriqon/mulled/builds/$TRAVIS_BUILD_ID\", "
  echo -n "\"packager\": \"$PACKAGER\"}"
}

function buildPackage {
  PACKAGER=$1
  PACKAGE=$2
  BINARY=$2
  ADDITIONAL_PACKAGES=$3

  PACKAGE=$PACKAGE BINARY=$BINARY ADDITIONAL_PACKAGES=$ADDITIONAL_PACKAGES ./involucro -f ${PACKAGER}.lua build package

  if [[ $TRAVIS_PULL_REQUEST == "false" ]]; then
    docker push thriqon/mulled:$PACKAGE > push.log
    grep digest push.log | cut -d " " -f 3 > digest.txt
    echo "UPLOAD"
    cat push.log
    echo "DIGEST"
    cat digest.txt

    API_FILENAME=page/images/$PACKAGE.json
    DATA_FILENAME=page/_data/$PACKAGE.json
    jsonForImage $PACKAGE $PACKAGER | jq . | tee $API_FILENAME $DATA_FILENAME
  fi
  
  PACKAGE=$PACKAGE BINARY=$BINARY ADDITIONAL_PACKAGES=$ADDITIONAL_PACKAGES ./involucro -f ${PACKAGER}.lua clean
}

(while read line; do
  if [[ $line == \#* ]]; then continue; fi
  IFS=$'\t' read -ra FIELDS <<< "$line"

  buildPackage ${FIELDS[0]} ${FIELDS[1]} ${FIELDS[2]} ${FIELDS[3]}
done) < packages.tsv

if [[ $TRAVIS_PULL_REQUEST == "false" ]]; then
  git config --global user.name "Travis BuildBot"
  git config --global user.email "support@travis-ci.org"

  (cd page ; git add . ; git commit -m "results for $TRAVIS_BUILD_NUMBER" -m "" -m "commit range $TRAVIS_COMMIT_RANGE" -m "travis build https://travis-ci.org/$TRAVIS_REPO_SLUG/builds/$TRAVIS_BUILD_ID" ; git push -q origin gh-pages > /dev/null 2>&1)
fi
