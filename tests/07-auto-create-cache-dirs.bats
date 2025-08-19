#!/usr/bin/env bats

load 'test-helper'

@test "repo cache directory auto-creation with absolute path" {
    # Clean up any existing cache
    rm -rf "/tmp/test-auto-cache-repo"

    # Set cache to non-existent directory with absolute path
    HELM_GIT_REPO_CACHE="/tmp/test-auto-cache-repo"
    export HELM_GIT_REPO_CACHE

    run helm_init "$HELM_HOME"
    [ $status = 0 ]
    run "$HELM_BIN" plugin install "$HELM_GIT_DIRNAME"
    [ $status = 0 ]

    # This should automatically create the cache directory
    run "$HELM_BIN" fetch -d "$HELM_GIT_OUTPUT" "git+https://github.com/jetstack/cert-manager@contrib/charts/index.yaml?ref=v0.5.2"
    [ $status = 0 ]

    # Verify the cache directory was created and has content
    run stat "/tmp/test-auto-cache-repo"
    [ $status = 0 ]
    run stat "/tmp/test-auto-cache-repo/github.com/jetstack/cert-manager"
    [ $status = 0 ]

    # Clean up
    rm -rf "/tmp/test-auto-cache-repo"
}

@test "chart cache directory auto-creation with absolute path" {
    # Clean up any existing cache
    rm -rf "/tmp/test-auto-cache-chart"

    # Set cache to non-existent directory with absolute path
    HELM_GIT_CHART_CACHE="/tmp/test-auto-cache-chart"
    export HELM_GIT_CHART_CACHE

    run helm_init "$HELM_HOME"
    [ $status = 0 ]
    run "$HELM_BIN" plugin install "$HELM_GIT_DIRNAME"
    [ $status = 0 ]

    # This should automatically create the cache directory
    run "$HELM_BIN" fetch -d "$HELM_GIT_OUTPUT" "git+https://github.com/jetstack/cert-manager@contrib/charts/index.yaml?ref=v0.5.2"
    [ $status = 0 ]

    # Verify the cache directory was created and has content
    run stat "/tmp/test-auto-cache-chart"
    [ $status = 0 ]
    # The exact hash subdirectory name varies, so just check that something was created
    run sh -c "ls '/tmp/test-auto-cache-chart' | wc -l"
    [ "$output" -gt 0 ]

    # Clean up
    rm -rf "/tmp/test-auto-cache-chart"
}

@test "both cache directories auto-creation with nested paths" {
    # Clean up any existing cache
    rm -rf "/tmp/test-cache"

    # Set both caches to non-existent nested directories
    HELM_GIT_REPO_CACHE="/tmp/test-cache/helm-git/repo"
    HELM_GIT_CHART_CACHE="/tmp/test-cache/helm-git/chart"
    export HELM_GIT_REPO_CACHE
    export HELM_GIT_CHART_CACHE

    run helm_init "$HELM_HOME"
    [ $status = 0 ]
    run "$HELM_BIN" plugin install "$HELM_GIT_DIRNAME"
    [ $status = 0 ]

    # This should automatically create both cache directories
    run "$HELM_BIN" fetch -d "$HELM_GIT_OUTPUT" "git+https://github.com/jetstack/cert-manager@contrib/charts/index.yaml?ref=v0.5.2"
    [ $status = 0 ]

    # Verify both cache directories were created
    run stat "/tmp/test-cache/helm-git/repo"
    [ $status = 0 ]
    run stat "/tmp/test-cache/helm-git/chart"
    [ $status = 0 ]

    # Verify they have content
    run stat "/tmp/test-cache/helm-git/repo/github.com/jetstack/cert-manager"
    [ $status = 0 ]
    run sh -c "ls '/tmp/test-cache/helm-git/chart' | wc -l"
    [ "$output" -gt 0 ]

    # Clean up
    rm -rf "/tmp/test-cache"
}
