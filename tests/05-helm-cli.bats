#!/usr/bin/env bats

load 'test-helper'

@test "helm_cli fetch index.yaml" {
    run helm_init "$HELM_HOME"
    [ $status = 0 ]
    run helm plugin install "$HELM_GIT_DIRNAME"
    [ $status = 0 ]
    run helm fetch -d "$HELM_GIT_OUTPUT" "git+https://github.com/jetstack/cert-manager@contrib/charts/index.yaml?ref=v0.5.2"
    [ $status = 0 ]
    run stat "$HELM_GIT_OUTPUT/index.yaml"
    [ $status = 0 ]
}

@test "helm_cli fetch cert-manager-v0.5.2.tgz" {
    run helm_init "$HELM_HOME"
    [ $status = 0 ]
    run helm plugin install "$HELM_GIT_DIRNAME"
    [ $status = 0 ]
    run helm fetch -d "$HELM_GIT_OUTPUT" "git+https://github.com/jetstack/cert-manager@contrib/charts/cert-manager-v0.5.2.tgz?ref=v0.5.2"
    [ $status = 0 ]
    run stat "$HELM_GIT_OUTPUT/cert-manager-v0.5.2.tgz"
    [ $status = 0 ]
}

@test "helm_cli fetch cert-manager-v0.5.2.tgz relative" {
    run helm_init "$HELM_HOME"
    [ $status = 0 ]
    run helm plugin install "$HELM_GIT_DIRNAME"
    [ $status = 0 ]
    run helm repo add cert-manager-v0.5.2 "git+https://github.com/jetstack/cert-manager@contrib/charts?ref=v0.5.2"
    [ $status = 0 ]
    run helm fetch -d "$HELM_GIT_OUTPUT" "cert-manager-v0.5.2/cert-manager"
    [ $status = 0 ]
    run stat "$HELM_GIT_OUTPUT/cert-manager-v0.5.2.tgz"
    [ $status = 0 ]
}

@test "helm_cli repo_add cert-manager-v0.5.2 charts" {
    run helm_init "$HELM_HOME"
    [ $status = 0 ]
    run helm plugin install "$HELM_GIT_DIRNAME"
    [ $status = 0 ]
    run helm repo add cert-manager-v0.5.2 "git+https://github.com/jetstack/cert-manager@contrib/charts?ref=v0.5.2"
    [ $status = 0 ]
    run grep cert-manager-v0.5.2 "$HELM_HOME/repository/repositories.yaml"
    [ -n "$output" ]
}

@test "helm_cli repo_add cert-manager-v0.5.2 direct" {
    run helm_init "$HELM_HOME"
    [ $status = 0 ]
    run helm plugin install "$HELM_GIT_DIRNAME"
    [ $status = 0 ]
    run helm repo add cert-manager-v0.5.2 "git+https://github.com/jetstack/cert-manager@contrib/charts/cert-manager?ref=v0.5.2"
    [ $status = 0 ]
    run grep cert-manager-v0.5.2 "$HELM_HOME/repository/repositories.yaml"
    [ -n "$output" ]
}
