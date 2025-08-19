#!/usr/bin/env bats

load 'test-helper'


@test "helm_cli fetch index.yaml and ensure repo is cached" {
    enable_repo_cache
    run helm_init "$HELM_HOME"
    [ $status = 0 ]
    run "$HELM_BIN" plugin install "$HELM_GIT_DIRNAME"
    [ $status = 0 ]
    run "$HELM_BIN" fetch -d "$HELM_GIT_OUTPUT" "git+https://github.com/jetstack/cert-manager@contrib/charts/index.yaml?ref=v0.5.2"
    [ $status = 0 ]
    echo "$output" | grep "First time I see https://github.com/jetstack/cert-manager"
    run "$HELM_BIN" fetch -d "$HELM_GIT_OUTPUT" "git+https://github.com/jetstack/cert-manager@contrib/charts/index.yaml?ref=v0.5.2"
    [ $status = 0 ]
    echo "$output" | grep "https://github.com/jetstack/cert-manager exists in cache"
}

@test "helm_cli fetch cert-manager-v0.5.2.tgz and ensure repo is cached" {
    enable_repo_cache
    run helm_init "$HELM_HOME"
    [ $status = 0 ]
    run "$HELM_BIN" plugin install "$HELM_GIT_DIRNAME"
    [ $status = 0 ]
    run "$HELM_BIN" fetch -d "$HELM_GIT_OUTPUT" "git+https://github.com/jetstack/cert-manager@contrib/charts/cert-manager-v0.5.2.tgz?ref=v0.5.2"
    [ $status = 0 ]
    echo "$output" | grep "First time I see https://github.com/jetstack/cert-manager"
    run "$HELM_BIN" fetch -d "$HELM_GIT_OUTPUT" "git+https://github.com/jetstack/cert-manager@contrib/charts/cert-manager-v0.5.2.tgz?ref=v0.5.2"
    [ $status = 0 ]
    echo "$output" | grep "https://github.com/jetstack/cert-manager exists in cache"
    run stat "$HELM_GIT_OUTPUT/cert-manager-v0.5.2.tgz"
    [ $status = 0 ]
}

@test "helm_cli fetch cert-manager-v0.5.2.tgz and ensure chart is cached" {
    enable_chart_cache
    run helm_init "$HELM_HOME"
    [ $status = 0 ]
    run "$HELM_BIN" plugin install "$HELM_GIT_DIRNAME"
    [ $status = 0 ]
    run "$HELM_BIN" fetch -d "$HELM_GIT_OUTPUT" "git+https://github.com/jetstack/cert-manager@contrib/charts/cert-manager-v0.5.2.tgz?ref=v0.5.2"
    echo "$output" | grep "Helm request not found in cache"
    [ $status = 0 ]
    run "$HELM_BIN" fetch -d "$HELM_GIT_OUTPUT" "git+https://github.com/jetstack/cert-manager@contrib/charts/cert-manager-v0.5.2.tgz?ref=v0.5.2"
    [ $status = 0 ]
    echo "$output" | grep "Returning cached helm request"
    run stat "$HELM_GIT_OUTPUT/cert-manager-v0.5.2.tgz"
    [ $status = 0 ]
}

@test "helm_cli fetch index.yaml and ensure chart cert-manager-v0.5.2.tgz is cached if strategy=repo" {
    enable_chart_cache
    set_chart_cache_strategy "repo"
    run helm_init "$HELM_HOME"
    [ $status = 0 ]
    run "$HELM_BIN" plugin install "$HELM_GIT_DIRNAME"
    [ $status = 0 ]
    run "$HELM_BIN" fetch -d "$HELM_GIT_OUTPUT" "git+https://github.com/jetstack/cert-manager@contrib/charts/index.yaml?ref=v0.5.2"
    [ $status = 0 ]
    echo "$output" | grep "Helm request not found in cache"
    run "$HELM_BIN" fetch -d "$HELM_GIT_OUTPUT" "git+https://github.com/jetstack/cert-manager@contrib/charts/cert-manager-v0.5.2.tgz?ref=v0.5.2"
    [ $status = 0 ]
    echo "$output" | grep "Returning cached helm request"
    run stat "$HELM_GIT_OUTPUT/cert-manager-v0.5.2.tgz"
    [ $status = 0 ]
}

@test "helm_cli fetch gateway and ensure only single chart is packaged" {
    enable_chart_cache
    run helm_init "$HELM_HOME"
    [ $status = 0 ]
    run "$HELM_BIN" plugin install "$HELM_GIT_DIRNAME"
    [ $status = 0 ]
    run "$HELM_BIN" fetch -d "$HELM_GIT_OUTPUT" "git+https://github.com/istio/istio@install/kubernetes/helm/istio-1.1.0.tgz?ref=1.1.0"
    [ $status = 0 ]
    echo "$output" | grep "Helm request not found in cache"
    run stat "$HELM_GIT_OUTPUT/istio-1.1.0.tgz"
    [ $status = 0 ]
    run bats_pipe ls -1 "$HELM_GIT_CHART_CACHE"/*/* \| grep -v index.yaml \| wc -l \| awk '{print $1}'
    [ "$output" -gt "1" ]
    run rm -rf "$HELM_GIT_CHART_CACHE"/*/*
    set_chart_cache_strategy "chart"
    run "$HELM_BIN" fetch -d "$HELM_GIT_OUTPUT" "git+https://github.com/istio/istio@install/kubernetes/helm/istio-1.1.0.tgz?ref=1.1.0"
    [ $status = 0 ]
    echo "$output" | grep "Helm request not found in cache"
    run stat "$HELM_GIT_OUTPUT/istio-1.1.0.tgz"
    [ $status = 0 ]
    run bats_pipe ls -1 "$HELM_GIT_CHART_CACHE"/*/* \| grep -v index.yaml \| wc -l \| awk '{print $1}'
    [ "$output" = "1" ]
}

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

