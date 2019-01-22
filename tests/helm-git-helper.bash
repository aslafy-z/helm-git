#!/usr/bin/env bash

export HELM_GIT_DIRNAME="$BATS_TEST_DIRNAME/.."
export HELM_GIT_DEBUG=1

# shellcheck disable=SC1090
source "$HELM_GIT_DIRNAME/helm-git-plugin.sh"

setup() {
  stashdir_init
}

teardown() {
  trap stashdir_clean EXIT
}
