#!/usr/bin/env bash

export HELM_GIT_DIRNAME="$BATS_TEST_DIRNAME/.."

# shellcheck source=helm-git-plugin.sh
source "$HELM_GIT_DIRNAME/helm-git-plugin.sh"

function _run_helm_git() { run main '' '' '' "$1"; }

setup() {
  HELM_BIN=${HELM_GIT_HELM_BIN:-${HELM_BIN:-helm}}
  HELM_HOME=$(mktemp -d "$BATS_TMPDIR/helm-git.helm-home.XXXXXX")
  XDG_DATA_HOME=$HELM_HOME
  HELM_GIT_OUTPUT="$(mktemp -d "$BATS_TMPDIR/helm-git.test-output.XXXXXX")"
  export HELM_BIN
  export HELM_HOME
  export XDG_DATA_HOME
  export HELM_GIT_OUTPUT
}

teardown() {
  rm -rf "$HELM_HOME"
  rm -rf "$HELM_GIT_OUTPUT"
}
