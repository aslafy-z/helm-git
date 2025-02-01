#!/usr/bin/env bash

export HELM_GIT_DEBUG=1
export HELM_GIT_DIRNAME="$BATS_TEST_DIRNAME/.."

if [ -z "$HELM_GIT_SOURCE" ]; then
  # shellcheck source=helm-git-plugin.sh
  source "$HELM_GIT_DIRNAME/helm-git-plugin.sh"
fi

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

  # Ensure we do not pollute runners helm repo list etc...
  HELM_CACHE_HOME=$(mktemp -d "$BATS_TMPDIR/helm-git.helm-cache-home.XXXXXX")
  HELM_CONFIG_HOME=$(mktemp -d "$BATS_TMPDIR/helm-git.helm-cache-home.XXXXXX")

  export HELM_CACHE_HOME
  export HELM_CONFIG_HOME
}

teardown() {
  [ "$BATS_TEST_COMPLETED" = "1" ] || {
    rm -rf "$HELM_HOME"
    rm -rf "$HELM_GIT_OUTPUT"
    rm -rf "$HELM_CACHE_HOME"
    rm -rf "$HELM_CONFIG_HOME"
  }
}

enable_chart_cache() {
    HELM_GIT_CHART_CACHE=$(mktemp -d "$BATS_TMPDIR/helm-git.chart-cache.XXXXXX")
    export HELM_GIT_CHART_CACHE
}
enable_repo_cache() {
    HELM_GIT_REPO_CACHE=$(mktemp -d "$BATS_TMPDIR/helm-git.repo-cache.XXXXXX")
    export HELM_GIT_REPO_CACHE
}
set_chart_cache_strategy() {
    HELM_GIT_CHART_CACHE_STRATEGY="$1"
    export HELM_GIT_CHART_CACHE_STRATEGY
}
