#!/bin/bash

set -e

if [[ "${TRAVIS_OS_NAME}" == "osx" ]]; then
  brew tap homebrew/versions;
  brew install gcc47 --use-llvm;
  brew install snappy lz4;
fi
