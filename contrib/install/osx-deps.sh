#!/bin/bash

set -e

if [[ "${TRAVIS_OS_NAME}" == "osx" ]]; then
  brew install gcc48 --use-llvm;
  brew install snappy lz4;
fi
