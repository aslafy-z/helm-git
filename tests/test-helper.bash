#!/usr/bin/env bash

export HELM_GIT_DIRNAME="$BATS_TEST_DIRNAME/.."

# shellcheck disable=SC1090
source "$HELM_GIT_DIRNAME/helm-git-plugin.sh"

function _run_helm_git() { run main '' '' '' "$1"; }

setup() {
  HELM_HOME=$(mktemp -d "$BATS_TMPDIR/helm-git.helm-home.XXXXXX")
  HELM_GIT_OUTPUT="$(mktemp -d "$BATS_TMPDIR/helm-git.test-output.XXXXXX")"
  export HELM_HOME
  export HELM_GIT_OUTPUT
}

teardown() {
  rm -rf "$HELM_HOME"
  rm -rf "$HELM_GIT_OUTPUT"
}
