#!/bin/bash

if [ $TRAVIS_TAG != "nightly" ]
  # We create nightly tag using the script so we don't want to run this script
  # when the tagged build is triggered.
  exit 0
fi

# if [ $TRAVIS_EVENT_TYPE != "cron" ]
#   exit 0
# fi

set -e

BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source ${BUILD_DIR}/nightly/github.sh

NIGHTLY_TAG="nightly"
DGRAPH_REPO="dgraph-io/dgraph"
DGRAPH_VERSION=$(git describe --abbrev=0)
DGRAPH_COMMIT=$(git rev-parse HEAD)
TAR_FILE="dgraph-linux-amd64-${DGRAPH_VERSION}.tar.gz"
NIGHTLY_FILE="${BUILD_DIR}/${TAR_FILE}"
ASSETS_FILE="${BUILD_DIR}/assets.tar.gz"

delete_old_nightly() {
  local release_id
  read release_id < <( \
    send_gh_api_request repos/${DGRAPH_REPO}/releases \
    | jq -r -c "(.[] | select(.tag_name == \"${NIGHTLY_TAG}\").id), \"\"") \
    || exit

  echo "release_id ${release_id}"
  if [[ ! -z "${release_id}" ]]; then
    echo "Deleting old nightly release"
    send_gh_api_request repos/${DGRAPH_REPO}/releases/${release_id} \
        DELETE \
        > /dev/null
  fi
}

get_release_body() {
  echo 'Dgraph development (pre-release) build.'
  echo 'You can run `tar -xzf dgraph-linux64.tar.gz` to unzip the tar.gz which creates a `dgraph` folder with the binaries.'
  echo 'See **[Get Started](http://docs.dgraph.io/master/get-started/#step-2-run-dgraph)** for documentation.'
}

upload_nightly() {
  echo "Creating release for tag ${NIGHTLY_TAG}."
  read release_id < <( \
    send_gh_api_data_request repos/${DGRAPH_REPO}/releases POST \
    "{ \"name\": \"Dgraph ${DGRAPH_VERSION}-dev\", \"tag_name\": \"${NIGHTLY_TAG}\", \
    \"prerelease\": true }" \
    | jq -r -c '.id') \
    || exit

  echo 'Updating release description.'
  send_gh_api_data_request repos/${DGRAPH_REPO}/releases/${release_id} PATCH \
    "{ \"body\": $(get_release_body | jq -s -c -R '.') }" \
    > /dev/null

  echo "Updating ${NIGHTLY_TAG} tag to point to ${DGRAPH_COMMIT}."
  send_gh_api_data_request repos/${DGRAPH_REPO}/git/refs/tags/${NIGHTLY_TAG} PATCH \
    "{ \"force\": true, \"sha\": \"${DGRAPH_COMMIT}\" }" \
    > /dev/null

  echo 'Uploading package.'
  local name="dgraph-linux64.tar.gz"
  upload_release_asset ${NIGHTLY_FILE} "$name" \
    ${DGRAPH_REPO} ${release_id} \
    > /dev/null

  echo $ASSETS_FILE
  upload_release_asset ${ASSETS_FILE} "assets.tar.gz" \
    ${DGRAPH_REPO} ${release_id} \
    > /dev/null
}

go get -u golang.org/x/net/context golang.org/x/text/unicode/norm google.golang.org/grpc

# Building embedded binaries.
echo "Building embedded binaries"
contrib/releases/build.sh
delete_old_nightly
upload_nightly