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

# Check if Helm version supports credential passing (>= 3.14.0)
helm_supports_credentials() {
    local helm_version
    helm_version=$($HELM_BIN version --short 2>/dev/null | head -1 | sed 's/v//' | cut -d'+' -f1 | cut -d'-' -f1)

    # If we can't get version, assume it doesn't support credentials
    [ -n "$helm_version" ] || return 1

    # Extract major.minor.patch using parameter expansion
    local major="${helm_version%%.*}"
    local rest="${helm_version#*.}"
    local minor="${rest%%.*}"
    local patch="${rest#*.}"

    # If patch is the same as rest, there was no second dot, so patch is 0
    [ "$patch" = "$rest" ] && patch=0

    # Ensure we have numeric values (basic check)
    case "$major" in ''|*[!0-9]*) return 1 ;; esac
    case "$minor" in ''|*[!0-9]*) return 1 ;; esac
    case "$patch" in ''|*[!0-9]*) patch=0 ;; esac

    # Check if version >= 3.14.0
    if [ "$major" -gt 3 ]; then
        return 0
    elif [ "$major" -eq 3 ] && [ "$minor" -gt 14 ]; then
        return 0
    elif [ "$major" -eq 3 ] && [ "$minor" -eq 14 ] && [ "$patch" -ge 0 ]; then
        return 0
    else
        return 1
    fi
}
