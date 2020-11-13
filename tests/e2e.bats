#!/usr/bin/env bats

load 'test-helper'

@test "helm/charts stable" {
    run helm_init "$HELM_HOME"
    [ $status = 0 ]
    run $HELM_BIN repo add stable https://charts.helm.sh/stable >/dev/null
    [ $status = 0 ]
    run $HELM_BIN repo add incubator https://charts.helm.sh/incubator >/dev/null
    [ $status = 0 ]
    _run_helm_git "git+https://github.com/helm/charts@stable/index.yaml?ref=master"
    [ $status = 0 ]
}

@test "helm/charts incubator" {
    run helm_init "$HELM_HOME"
    [ $status = 0 ]
    run $HELM_BIN repo add stable https://charts.helm.sh/stable >/dev/null
    [ $status = 0 ]
    run $HELM_BIN repo add incubator https://charts.helm.sh/incubator >/dev/null
    [ $status = 0 ]
    _run_helm_git "git+https://github.com/helm/charts@incubator/index.yaml?ref=master"
    [ $status = 0 ]
}

@test "jetstack/cert-manager v0.7.0 index.yaml" {
    run helm_init "$HELM_HOME"
    [ $status = 0 ]
    _run_helm_git "git+https://github.com/jetstack/cert-manager@deploy/charts/index.yaml?ref=v0.7.0"
    [ $status = 0 ]
}

@test "helm-git fails with incorrect user defined HELM_BIN path" {
    export HELM_GIT_HELM_BIN=/wrong/path
    helm_init "$HELM_HOME"
    _run_helm_git "git+https://github.com/jetstack/cert-manager@deploy/charts/index.yaml?ref=v0.7.0"
    [ $status = 1 ]
}

@test "helm-git succeeds with correct user defined HELM_BIN path" {
    export HELM_GIT_HELM_BIN=helm
    helm_init "$HELM_HOME"
    _run_helm_git "git+https://github.com/jetstack/cert-manager@deploy/charts/index.yaml?ref=v0.7.0"
    [ $status = 0 ]
}
