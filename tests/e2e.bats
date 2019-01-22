#!/usr/bin/env bats

load 'helm-git-helper'

function _run_helm_git() { run $HELM_GIT_DIRNAME/helm-git '' '' '' "$1"; }

@test "helm/charts stable" {
    export HELM_HOME=$(stashdir_new "helm_home")
    run helm_init "$HELM_HOME"
    helm repo add stable https://kubernetes-charts.storage.googleapis.com/ >/dev/null
    helm repo add incubator https://kubernetes-charts-incubator.storage.googleapis.com/ >/dev/null
    run _run_helm_git "git+https://github.com/helm/charts@stable/index.yaml?ref=master"
    [ $status = 0 ]
}

@test "helm/charts incubator" {
    export HELM_HOME=$(stashdir_new "helm_home")
    run helm_init "$HELM_HOME"
    helm repo add stable https://kubernetes-charts.storage.googleapis.com/ >/dev/null
    helm repo add incubator https://kubernetes-charts-incubator.storage.googleapis.com/ >/dev/null
    run _run_helm_git "git+https://github.com/helm/charts@incubator/index.yaml?ref=master"
    [ $status = 0 ]
}
