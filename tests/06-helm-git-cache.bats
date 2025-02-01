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
    run "$HELM_BIN" fetch -d "$HELM_GIT_OUTPUT" "git+https://github.com/istio/istio@manifests/charts/gateway-1.0.0.tgz?ref=1.24.2"
    [ $status = 0 ]
    echo "$output" | grep "Helm request not found in cache"
    run stat "$HELM_GIT_OUTPUT/gateway-1.0.0.tgz"
    [ $status = 0 ]
    run bats_pipe ls -1 "$HELM_GIT_CHART_CACHE"/*/* \| grep -v index.yaml \| wc -l \| awk '{print $1}'
    [ "$output" -gt "1" ]
    run rm -rf "$HELM_GIT_CHART_CACHE"/*/*
    set_chart_cache_strategy "chart"
    run "$HELM_BIN" fetch -d "$HELM_GIT_OUTPUT" "git+https://github.com/istio/istio@manifests/charts/gateway-1.0.0.tgz?ref=1.24.2"
    [ $status = 0 ]
    echo "$output" | grep "Helm request not found in cache"
    run stat "$HELM_GIT_OUTPUT/gateway-1.0.0.tgz"
    [ $status = 0 ]
    run bats_pipe ls -1 "$HELM_GIT_CHART_CACHE"/*/* \| grep -v index.yaml \| wc -l \| awk '{print $1}'
    [ "$output" = "1" ]
}

