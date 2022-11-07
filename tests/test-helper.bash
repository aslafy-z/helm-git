#!/usr/bin/env bash

export HELM_GIT_DEBUG=1
export HELM_GIT_DIRNAME="$BATS_TEST_DIRNAME/.."

# shellcheck source=helm-git-plugin.sh
source "$HELM_GIT_DIRNAME/helm-git-plugin.sh"

function _run_helm_git() { run main '' '' '' "$1"; }

setup() {
  FIXTURES_GIT_REPO=${FIXTURES_GIT_REPO:-"https://github.com/aslafy-z/helm-git"}
  FIXTURES_GIT_REF=${FIXTURES_GIT_REF:-"master"}
  BATS_TEST_TIMEOUT=300
  HELM_BIN=${HELM_GIT_HELM_BIN:-${HELM_BIN:-helm}}
  HELM_HOME=$(mktemp -d "$BATS_TMPDIR/helm-git.helm-home.XXXXXX")
  XDG_DATA_HOME=$HELM_HOME
  HELM_GIT_OUTPUT="$(mktemp -d "$BATS_TMPDIR/helm-git.test-output.XXXXXX")"
  export FIXTURES_GIT_BRANCH
  export BATS_TEST_TIMEOUT
  export HELM_BIN
  export HELM_HOME
  export XDG_DATA_HOME
  export HELM_GIT_OUTPUT
}

teardown() {
  rm -rf "$HELM_HOME"
  rm -rf "$HELM_GIT_OUTPUT"
}
