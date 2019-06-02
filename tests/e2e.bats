#!/usr/bin/env bats

load 'test-helper'

@test "helm/charts stable" {
    run helm_init "$HELM_HOME"
    helm repo add stable https://kubernetes-charts.storage.googleapis.com/ >/dev/null
    helm repo add incubator https://kubernetes-charts-incubator.storage.googleapis.com/ >/dev/null
    run _run_helm_git "git+https://github.com/helm/charts@stable/index.yaml?ref=master"
    [ $status = 0 ]
}

@test "helm/charts incubator" {
    run helm_init "$HELM_HOME"
    helm repo add stable https://kubernetes-charts.storage.googleapis.com/ >/dev/null
    helm repo add incubator https://kubernetes-charts-incubator.storage.googleapis.com/ >/dev/null
    run _run_helm_git "git+https://github.com/helm/charts@incubator/index.yaml?ref=master"
    [ $status = 0 ]
}

@test "jetstack/cert-manager v0.7.0 index.yaml" {
    run helm_init "$HELM_HOME"
    run _run_helm_git "git+https://github.com/jetstack/cert-manager@deploy/charts/index.yaml?ref=v0.7.0"
    [ $status = 0 ]
}
